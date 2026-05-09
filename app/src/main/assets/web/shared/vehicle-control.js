/**
 * Vehicle Control — VFX Engine
 * Three.js car with GSAP energy-based animations
 * State sync with BYD vehicle APIs
 *
 * Compatibility: Chrome 58+ (BYD DiLink Android 7.1 WebView)
 * - No ES modules, no import maps, no optional chaining, no nullish coalescing
 * - Uses UMD globals: THREE, THREE.GLTFLoader, THREE.OrbitControls, gsap
 */

var VC = {
    // Three.js core (initialized in init())
    scene: null,
    camera: null,
    renderer: null,
    controls: null,
    carModel: null,

    // Materials (initialized in initThreeJS())
    baseColor: null,
    bodyPaintMeshes: [],

    // State
    vehicleState: {
        locked: null,
        trunkOpen: false,
        doors: { lf: 1, rf: 1, lr: 1, rr: 1, trunk: -1, hood: -1 },
        windows: { lf: 0, rf: 0, lr: 0, rr: 0 },
        soc: 0,
        rangeKm: 0,
        cloudConfigured: false,
        acOn: false,
        acTemp: 22,
        acFan: 3,
        seatHeat: { 1: 0, 2: 0 },  // 0=off, 1=low, 2=high
        seatCool: { 1: 0, 2: 0 }
    },

    pollInterval: null,
    _toastTimer: null,
    stateGlows: {},  // persistent glow lights keyed by position name
    _3dViewActive: false,
    _skySphere: null,
    _videoTexture: null,

    // Color presets — realistic car paint colors
    colorPresets: [
        { name: 'Aurora White', hex: '#E8E8EC' },
        { name: 'Cosmos Black', hex: '#1A1A1E' },
        { name: 'Atlantic Blue', hex: '#1E3A5F' },
        { name: 'Deepsea Green', hex: '#1B4D3E' },
        { name: 'Burgundy Red', hex: '#6B1D2A' },
        { name: 'Storm Grey', hex: '#5C5C66' }
    ],

    // ==================== INITIALIZATION ====================

    init: function() {
        this.baseColor = new THREE.Color(0xE8E8EC); // Default: Aurora White
        this.initThreeJS();
        this.initColorPicker();
        this.loadSavedColor();
        this.loadModel();
        this.bindControls();
        this.startStateSync();
        this.checkCloudStatus();
        this.requestCloudLockRefresh();
        this.startCloudLockSync();
        this.animate();
        this.init3dButton();
        this.initCloudModal();
    },

    initThreeJS: function() {
        var self = this;

        this.scene = new THREE.Scene();

        // Adjust camera for mobile portrait — closer zoom on narrow screens
        var isMobile = window.innerWidth < 768;
        var fov = isMobile ? 42 : 50;
        this.camera = new THREE.PerspectiveCamera(
            fov, window.innerWidth / window.innerHeight, 0.1, 1000
        );
        this.camera.position.set(isMobile ? 3.5 : 4, isMobile ? 2.2 : 2.5, isMobile ? 4.5 : 5);

        this.renderer = new THREE.WebGLRenderer({
            canvas: document.getElementById('vehicleCanvas'),
            antialias: true,
            alpha: true
        });
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 3));
        this.renderer.setClearColor(0x0F0F12, 1);
        this.renderer.outputEncoding = THREE.sRGBEncoding;
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.2;

        this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.08;
        this.controls.minDistance = 3;
        this.controls.maxDistance = 12;
        // Lock vertical rotation — keep camera above the car, no going underneath
        this.controls.minPolarAngle = Math.PI * 0.2;  // ~36° from top (don't go fully overhead)
        this.controls.maxPolarAngle = Math.PI * 0.48;  // ~86° (just above horizon, never below car)
        this.controls.enablePan = false;  // No panning — car stays centered
        this.controls.autoRotate = true;
        this.controls.autoRotateSpeed = 0.3;

        this.controls.addEventListener('start', function() {
            self.controls.autoRotate = false;
        });

        // Scene lighting — enhance the model's own materials
        this.addLighting();
        this.addGroundGrid();

        window.addEventListener('resize', function() { self.onResize(); });
    },

    addLighting: function() {
        // Environment lighting for PBR materials
        var ambient = new THREE.HemisphereLight(0x88aacc, 0x222244, 1.0);
        this.scene.add(ambient);

        // Key light — strong top-front
        var keyLight = new THREE.DirectionalLight(0xffffff, 1.2);
        keyLight.position.set(5, 8, 5);
        this.scene.add(keyLight);

        // Fill light
        var fillLight = new THREE.DirectionalLight(0x8899bb, 0.6);
        fillLight.position.set(-5, 4, -3);
        this.scene.add(fillLight);

        // Rim light from below — cyberpunk floor glow in selected color
        var rimLight = new THREE.PointLight(0x00E5FF, 0.6, 15);
        rimLight.position.set(0, -1.5, 0);
        this.scene.add(rimLight);
        this.rimLight = rimLight;

        // Back accent
        var backLight = new THREE.DirectionalLight(0x6644aa, 0.3);
        backLight.position.set(0, 3, -6);
        this.scene.add(backLight);
    },

    addGroundGrid: function() {
        var gridHelper = new THREE.GridHelper(20, 40, 0x1a1a2e, 0x1a1a2e);
        gridHelper.position.y = -0.01;
        gridHelper.material.opacity = 0.15;
        gridHelper.material.transparent = true;
        this.scene.add(gridHelper);
        this._groundGrid = gridHelper;
    },

    loadModel: function() {
        var self = this;

        // Sanity check — if Three.js failed to load (e.g. local extraction failed),
        // bail with a clear message instead of throwing in the loader constructor.
        if (typeof THREE === 'undefined' || !THREE.GLTFLoader) {
            this._showModelError('3D engine failed to load. Tap Retry to reload.');
            return;
        }

        var loader = new THREE.GLTFLoader();

        // Draco decoder — the GLB uses Draco mesh compression.
        // Local path: assets/web/shared/vendor/draco/ (extracted to /data/local/tmp/web/shared/vendor/draco/).
        // We force the JS decoder (no WASM) for Chrome 58 compatibility and to avoid the
        // wasm MIME quirks on some BYD WebViews.
        var dracoLoader = new THREE.DRACOLoader();
        dracoLoader.setDecoderPath('../shared/vendor/draco/');
        dracoLoader.setDecoderConfig({ type: 'js' });
        loader.setDRACOLoader(dracoLoader);

        var modelPath = '../shared/models/byd_seal_optimized.glb';

        // Track whether load completed; arm a hard timeout so the spinner can never spin forever.
        // BYD AVN networks can stall mid-download with no error event; without this the UI hangs.
        this._modelLoadComplete = false;
        if (this._modelLoadTimeout) clearTimeout(this._modelLoadTimeout);
        this._modelLoadTimeout = setTimeout(function() {
            if (!self._modelLoadComplete) {
                self._showModelError('Model load timed out. Tap Retry.');
            }
        }, 20000);  // 20s — generous for slow head-unit storage

        loader.load(
            modelPath,
            function(gltf) {
                self._modelLoadComplete = true;
                if (self._modelLoadTimeout) { clearTimeout(self._modelLoadTimeout); self._modelLoadTimeout = null; }
                self.carModel = gltf.scene;

                self.carModel.traverse(function(node) {
                    if (node.isMesh) {
                        // Identify body paint panels vs glass/chrome/rubber/interior
                        // Body paint: opaque, non-transparent, typically the largest colored surfaces
                        var mat = node.material;
                        var isBodyPaint = false;

                        if (mat && !mat.transparent && mat.opacity > 0.9) {
                            // Check if it's NOT glass (glass is usually transparent or has low opacity)
                            // Check if it's NOT black rubber/tyre (very dark, roughness ~1)
                            // Check if it's NOT chrome (metalness ~1, very light color)
                            var col = mat.color;
                            if (col) {
                                var brightness = col.r * 0.299 + col.g * 0.587 + col.b * 0.114;
                                var isVeryDark = brightness < 0.08;  // black rubber, tyres
                                var isVeryBright = brightness > 0.85; // chrome, lights
                                var isGlass = mat.transparent || (mat.opacity < 0.95);
                                var metalness = mat.metalness !== undefined ? mat.metalness : 0;

                                // Body paint: mid-range brightness, not chrome-level metalness
                                if (!isVeryDark && !isVeryBright && !isGlass && metalness < 0.95) {
                                    isBodyPaint = true;
                                }
                            }
                        }

                        if (isBodyPaint) {
                            // Store original color for reference
                            node.userData.originalColor = mat.color.clone();
                            node.userData.isBodyPaint = true;
                            // Apply the user's chosen color
                            mat.color.set(self.baseColor);
                            mat.needsUpdate = true;
                            self.bodyPaintMeshes.push(node);
                        }

                        // Keep the model's original material for everything else
                        if (mat && mat.isMeshStandardMaterial) {
                            mat.envMapIntensity = 1.0;
                            mat.needsUpdate = true;
                        }
                    }
                });

                var box = new THREE.Box3().setFromObject(self.carModel);
                var center = box.getCenter(new THREE.Vector3());
                self.carModel.position.sub(center);
                self.carModel.position.y += 0.1;

                // The Android WebView on the BYD head unit renders at a
                // smaller effective canvas than mobile browsers, so the car
                // looks tiny. Bump the model scale when running embedded.
                if (window.AndroidBridge) {
                    self.carModel.scale.multiplyScalar(1.35);
                }

                self.scene.add(self.carModel);

                var loadingEl = document.getElementById('vcLoading');
                if (loadingEl) loadingEl.classList.add('hidden');
                self.triggerIdlePulse();
            },
            function(progress) {
                if (progress.total > 0) {
                    var pct = Math.round((progress.loaded / progress.total) * 100);
                    var textEl = document.querySelector('.vc-loading-text');
                    if (textEl) textEl.textContent = 'Loading model... ' + pct + '%';
                }
            },
            function(error) {
                console.error('Model load error:', error);
                self._modelLoadComplete = true;  // Don't fire timeout error after this.
                if (self._modelLoadTimeout) { clearTimeout(self._modelLoadTimeout); self._modelLoadTimeout = null; }
                self._showModelError('Model not found. Tap Retry to try again.');
            }
        );
    },

    /**
     * Surface a user-actionable error in the loading overlay with a Retry button.
     * Idempotent: safe to call from timeout, error callback, or precondition guards.
     */
    _showModelError: function(msg) {
        var loadingEl = document.getElementById('vcLoading');
        if (loadingEl) loadingEl.classList.remove('hidden');
        var textEl = document.querySelector('.vc-loading-text');
        if (textEl) {
            textEl.textContent = msg || 'Model load failed.';
            textEl.style.textAlign = 'center';
            textEl.style.lineHeight = '1.6';
        }
        var spinner = document.querySelector('.vc-loading-spinner');
        if (spinner) spinner.style.display = 'none';
        var retryBtn = document.getElementById('vcLoadingRetry');
        if (retryBtn) {
            retryBtn.style.display = 'inline-block';
            // Re-bind defensively (avoid stacking listeners across retries)
            var self = this;
            retryBtn.onclick = function() {
                retryBtn.style.display = 'none';
                if (spinner) spinner.style.display = '';
                if (textEl) textEl.textContent = 'Loading model...';
                self.loadModel();
            };
        }
    },

    onResize: function() {
        var isMobile = window.innerWidth < 768;
        this.camera.fov = isMobile ? 42 : 50;
        this.camera.aspect = window.innerWidth / window.innerHeight;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(window.innerWidth, window.innerHeight);
    },

    animate: function() {
        var self = this;
        requestAnimationFrame(function() { self.animate(); });
        if (this.controls) this.controls.update();
        // Update canvas texture each frame when 3D view is active
        if (this._3dViewActive && this._videoTexture) {
            this._videoTexture.needsUpdate = true;
        }
        if (this.renderer && this.scene && this.camera) {
            this.renderer.render(this.scene, this.camera);
        }
    },

    // ==================== VFX ANIMATIONS ====================

    /** Flash all body paint meshes to a color and back */
    flashBodyColor: function(flashColor, duration, repeats, callback) {
        var self = this;
        if (this.bodyPaintMeshes.length === 0) return;

        // Store current colors
        var origColors = [];
        for (var i = 0; i < this.bodyPaintMeshes.length; i++) {
            origColors.push(this.bodyPaintMeshes[i].material.color.clone());
        }

        // Flash each body mesh
        for (var j = 0; j < this.bodyPaintMeshes.length; j++) {
            gsap.to(this.bodyPaintMeshes[j].material.color, {
                r: flashColor.r, g: flashColor.g, b: flashColor.b,
                duration: duration || 0.15,
                yoyo: true,
                repeat: repeats || 1,
                ease: 'power2.out',
                onComplete: (function(idx) {
                    return function() {
                        // Restore original color
                        self.bodyPaintMeshes[idx].material.color.copy(origColors[idx]);
                        self.bodyPaintMeshes[idx].material.needsUpdate = true;
                        if (idx === self.bodyPaintMeshes.length - 1 && callback) callback();
                    };
                })(j)
            });
        }
    },

    triggerIdlePulse: function() {
        // No-op — car looks good static with clean materials
    },

    triggerUnlockVFX: function() {
        var self = this;
        if (!this.carModel) return;
        var white = new THREE.Color(0xFFFFFF);

        this.flashBodyColor(white, 0.12, 3, null);

        // Scale bounce
        gsap.to(this.carModel.scale, {
            x: 1.02, y: 1.02, z: 1.02,
            duration: 0.2,
            yoyo: true,
            repeat: 1,
            ease: 'power2.out'
        });
    },

    triggerLockVFX: function() {
        var self = this;
        if (!this.carModel) return;
        var red = new THREE.Color(0xFF0055);

        this.flashBodyColor(red, 0.12, 1, null);

        gsap.to(this.carModel.scale, {
            x: 0.98, y: 0.98, z: 0.98,
            duration: 0.15,
            yoyo: true,
            repeat: 1,
            ease: 'power2.out'
        });
    },

    triggerSonarVFX: function(x, y, z, color) {
        var self = this;
        if (!this.carModel) return;
        var ringColor = color || this.baseColor;

        var ringGeo = new THREE.RingGeometry(0.1, 0.15, 32);
        var ringMat = new THREE.MeshBasicMaterial({
            color: ringColor,
            side: THREE.DoubleSide,
            transparent: true,
            opacity: 1.0
        });
        var sonarRing = new THREE.Mesh(ringGeo, ringMat);
        sonarRing.position.set(x, y, z);
        sonarRing.rotation.x = Math.PI / 2;
        this.carModel.add(sonarRing);

        gsap.to(sonarRing.scale, {
            x: 6, y: 6, z: 6,
            duration: 1.2,
            ease: 'power2.out'
        });
        gsap.to(ringMat, {
            opacity: 0,
            duration: 1.2,
            ease: 'power2.out',
            onComplete: function() {
                if (self.carModel) self.carModel.remove(sonarRing);
                ringGeo.dispose();
                ringMat.dispose();
            }
        });
    },

    triggerTrunkVFX: function(opening) {
        var self = this;
        var color = opening ? this.baseColor : new THREE.Color(0xFF0055);
        this.triggerSonarVFX(0, 0.8, -2.2, color);
        if (opening) {
            setTimeout(function() { self.triggerSonarVFX(0, 0.8, -2.2, color); }, 200);
        }
    },

    triggerDoorVFX: function(door, opening) {
        var positions = {
            lf: { x: 1.0, y: 0.6, z: 0.5 },
            rf: { x: -1.0, y: 0.6, z: 0.5 },
            lr: { x: 1.0, y: 0.6, z: -0.5 },
            rr: { x: -1.0, y: 0.6, z: -0.5 }
        };
        var pos = positions[door];
        if (!pos) return;
        var color = opening ? this.baseColor : new THREE.Color(0x22C55E);
        this.triggerSonarVFX(pos.x, pos.y, pos.z, color);
    },

    triggerWindowVFX: function(area, opening) {
        var positions = {
            lf: { x: 1.0, y: 0.9, z: 0.5 },
            rf: { x: -1.0, y: 0.9, z: 0.5 },
            lr: { x: 1.0, y: 0.9, z: -0.5 },
            rr: { x: -1.0, y: 0.9, z: -0.5 }
        };
        var pos = positions[area];
        if (!pos) return;
        var color = opening ? new THREE.Color(0x38BDF8) : this.baseColor;
        this.triggerSonarVFX(pos.x, pos.y, pos.z, color);
    },

    triggerFlashVFX: function() {
        if (!this.carModel) return;
        var white = new THREE.Color(0xFFFFFF);
        this.flashBodyColor(white, 0.08, 5, null);
    },

    /** Start continuous AC sonar wave effect — semi-circular ring sweeps front to back */
    startAcSonar: function() {
        if (this._acSonarInterval) return; // already running
        var self = this;
        this._acSonarMeshes = [];

        function spawnAcRing() {
            if (!self.carModel) return;
            var ringGeo = new THREE.RingGeometry(0.1, 0.15, 32);
            var ringMat = new THREE.MeshBasicMaterial({
                color: 0x38BDF8,
                side: THREE.DoubleSide,
                transparent: true,
                opacity: 0.8
            });
            var ring = new THREE.Mesh(ringGeo, ringMat);
            ring.position.set(0, 0.5, 1.5);
            ring.rotation.x = Math.PI / 2;
            self.carModel.add(ring);
            self._acSonarMeshes.push(ring);

            // Move from z=1.5 to z=-2.0 over 1.5s while fading out
            gsap.to(ring.position, {
                z: -2.0,
                duration: 1.5,
                ease: 'linear'
            });
            gsap.to(ringMat, {
                opacity: 0,
                duration: 1.5,
                ease: 'linear',
                onComplete: function() {
                    if (self.carModel) self.carModel.remove(ring);
                    ringGeo.dispose();
                    ringMat.dispose();
                    var idx = self._acSonarMeshes.indexOf(ring);
                    if (idx !== -1) self._acSonarMeshes.splice(idx, 1);
                }
            });
        }

        spawnAcRing();
        this._acSonarInterval = setInterval(function() {
            spawnAcRing();
        }, 2000);
    },

    /** Stop continuous AC sonar effect */
    stopAcSonar: function() {
        if (this._acSonarInterval) {
            clearInterval(this._acSonarInterval);
            this._acSonarInterval = null;
        }
        if (this._acSonarMeshes && this.carModel) {
            for (var i = 0; i < this._acSonarMeshes.length; i++) {
                var mesh = this._acSonarMeshes[i];
                gsap.killTweensOf(mesh.position);
                gsap.killTweensOf(mesh.material);
                this.carModel.remove(mesh);
                mesh.geometry.dispose();
                mesh.material.dispose();
            }
        }
        this._acSonarMeshes = [];
    },

    // ==================== COLOR PICKER ====================

    initColorPicker: function() {
        var self = this;
        var container = document.getElementById('colorPicker');
        if (!container) return;

        for (var i = 0; i < this.colorPresets.length; i++) {
            (function(preset, idx) {
                var swatch = document.createElement('div');
                swatch.className = 'vc-swatch' + (idx === 0 ? ' active' : '');
                swatch.style.backgroundColor = preset.hex;
                swatch.title = preset.name;
                swatch.setAttribute('data-hex', preset.hex);
                swatch.addEventListener('click', function(e) {
                    e.stopPropagation();
                    self.setColor(preset.hex, swatch);
                });
                // Also handle touchend for WebView reliability
                swatch.addEventListener('touchend', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    self.setColor(preset.hex, swatch);
                });
                container.appendChild(swatch);
            })(this.colorPresets[i], i);
        }

        // Custom color — use a text hex input fallback for WebView compatibility
        // (input type="color" doesn't work on Android 7.1 WebView / Chrome 58)
        var custom = document.createElement('div');
        custom.className = 'vc-swatch-custom';
        custom.title = 'Custom color';
        custom.style.position = 'relative';
        
        // Try native color picker first, fall back gracefully
        var input = document.createElement('input');
        input.type = 'color';
        input.value = '#E8E8EC';
        input.addEventListener('input', function(e) {
            self.setColor(e.target.value, null);
            custom.style.backgroundColor = e.target.value;
        });
        input.addEventListener('change', function(e) {
            self.setColor(e.target.value, null);
            custom.style.backgroundColor = e.target.value;
        });
        custom.appendChild(input);
        container.appendChild(custom);
    },

    setColor: function(hex, activeSwatch) {
        this.baseColor.set(hex);

        // Update body paint color on all identified body panels
        var newColor = new THREE.Color(hex);
        for (var i = 0; i < this.bodyPaintMeshes.length; i++) {
            var mesh = this.bodyPaintMeshes[i];
            if (mesh.material && mesh.material.color) {
                mesh.material.color.copy(newColor);
                mesh.material.needsUpdate = true;
            }
        }

        // Update rim light color
        if (this.rimLight) {
            this.rimLight.color.set(hex);
        }

        // Update active swatch
        var swatches = document.querySelectorAll('.vc-swatch');
        for (var i = 0; i < swatches.length; i++) {
            swatches[i].classList.remove('active');
        }
        if (activeSwatch) activeSwatch.classList.add('active');

        // Persist
        try { localStorage.setItem('vc_color', hex); } catch(e) {}
    },

    loadSavedColor: function() {
        var self = this;
        try {
            var saved = localStorage.getItem('vc_color');
            if (saved) {
                this.baseColor.set(saved);
                if (this.rimLight) this.rimLight.color.set(saved);
                
                // Apply to body paint meshes if model already loaded
                if (this.bodyPaintMeshes.length > 0) {
                    var newColor = new THREE.Color(saved);
                    for (var j = 0; j < this.bodyPaintMeshes.length; j++) {
                        if (this.bodyPaintMeshes[j].material && this.bodyPaintMeshes[j].material.color) {
                            this.bodyPaintMeshes[j].material.color.copy(newColor);
                            this.bodyPaintMeshes[j].material.needsUpdate = true;
                        }
                    }
                }
                
                setTimeout(function() {
                    var swatches = document.querySelectorAll('.vc-swatch');
                    for (var i = 0; i < swatches.length; i++) {
                        swatches[i].classList.remove('active');
                        var dataHex = swatches[i].getAttribute('data-hex');
                        if (dataHex && dataHex.toLowerCase() === saved.toLowerCase()) {
                            swatches[i].classList.add('active');
                        }
                    }
                }, 100);
            }
        } catch(e) {}
    },

    // ==================== PANEL TOGGLE (Tabbed Controls) ====================

    _activePanel: null,

    togglePanel: function(panelId, tabEl) {
        var panel = document.getElementById('vcPanel');
        var allPanels = panel.querySelectorAll('.vc-panel-row');
        var allTabs = document.querySelectorAll('.vc-tab');
        var target = document.getElementById(panelId);

        // If tapping the already-active tab, collapse
        if (this._activePanel === panelId) {
            panel.classList.remove('open');
            panel.classList.remove('vc-panel-tall');
            this._activePanel = null;
            for (var i = 0; i < allTabs.length; i++) allTabs[i].classList.remove('active');
            for (var j = 0; j < allPanels.length; j++) allPanels[j].style.display = 'none';
            return;
        }

        // Hide all panels, show target
        for (var k = 0; k < allPanels.length; k++) allPanels[k].style.display = 'none';
        if (target) target.style.display = 'flex';

        // Update tab active state
        for (var m = 0; m < allTabs.length; m++) allTabs[m].classList.remove('active');
        if (tabEl) tabEl.classList.add('active');

        // Open the panel container — Windows needs extra vertical space for
        // the per-window preset rows.
        panel.classList.add('open');
        if (panelId === 'panelWindows') panel.classList.add('vc-panel-tall');
        else panel.classList.remove('vc-panel-tall');
        this._activePanel = panelId;
    },

    /** Update tab dot indicators based on vehicle state */
    updateTabIndicators: function() {
        var tabs = document.querySelectorAll('.vc-tab');
        if (!tabs.length) return;

        // Security tab — has-active if locked (null = unknown, don't show)
        var secTab = tabs[0];
        if (secTab) {
            if (this.vehicleState.locked === true) secTab.classList.add('has-active');
            else secTab.classList.remove('has-active');
        }

        // Trunk tab — has-active if trunk open
        var trunkTab = tabs[1];
        if (trunkTab) {
            if (this.vehicleState.trunkOpen === true) trunkTab.classList.add('has-active');
            else trunkTab.classList.remove('has-active');
        }

        // Climate tab — has-active if AC on (only if explicitly true, not undefined/null)
        var climateTab = tabs[2];
        if (climateTab) {
            if (this.vehicleState.acOn === true) climateTab.classList.add('has-active');
            else climateTab.classList.remove('has-active');
        }
    },

    // ==================== CONTROL BINDINGS ====================

    bindControls: function() {
        var self = this;

        // Lock
        this.bindBtn('btnLock', function() {
            if (!self.requireCloud()) return;
            self.setPending('btnLock', true);
            self.triggerLockVFX();
            self.apiPost('/api/vehicle/lock').then(function(result) {
                self.setPending('btnLock', false);
                if (result.success && result.commandSuccess) {
                    self.toast('Car locked', 'success');
                } else {
                    self.toast(result.error || 'Lock failed', 'error');
                }
            });
        });

        // Unlock
        this.bindBtn('btnUnlock', function() {
            if (!self.requireCloud()) return;
            self.setPending('btnUnlock', true);
            self.triggerUnlockVFX();
            self.apiPost('/api/vehicle/unlock').then(function(result) {
                self.setPending('btnUnlock', false);
                if (result.success && result.commandSuccess) {
                    self.toast('Car unlocked', 'success');
                } else {
                    self.toast(result.error || 'Unlock failed', 'error');
                }
            });
        });

        // Trunk open — shows progress: Unlocking → Opening
        this.bindBtn('btnTrunkOpen', function() {
            if (!self.requireCloud()) return;
            self.setPending('btnTrunkOpen', true);
            self.toast('Unlocking car...', 'info');
            self.triggerUnlockVFX();
            self.apiPost('/api/vehicle/trunk', { action: 'open' }).then(function(result) {
                self.setPending('btnTrunkOpen', false);
                if (result.success) {
                    self.triggerTrunkVFX(true);
                    self.toast('Trunk opening', 'success');
                } else {
                    self.toast(result.error || 'Trunk failed', 'error');
                }
            });
        });

        // Trunk close — closes trunk via local HAL + locks car
        this.bindBtn('btnTrunkClose', function() {
            self.setPending('btnTrunkClose', true);
            self.toast('Closing trunk...', 'info');
            self.triggerLockVFX();
            self.apiPost('/api/vehicle/trunk', { action: 'close' }).then(function(result) {
                self.setPending('btnTrunkClose', false);
                if (result.success) {
                    self.triggerTrunkVFX(false);
                    self.toast('Trunk closing', 'success');
                } else {
                    self.toast(result.error || 'Trunk close failed', 'error');
                }
            });
        });

        // Flash lights
        this.bindBtn('btnFlash', function() {
            if (!self.requireCloud()) return;
            self.setPending('btnFlash', true);
            self.triggerFlashVFX();
            self.apiPost('/api/vehicle/flash').then(function(result) {
                self.setPending('btnFlash', false);
                if (result.success) self.toast('Lights flashed', 'info');
                else self.toast(result.error || 'Flash failed', 'error');
            });
        });

        // Per-window preset levels — backend runs closed-loop to drive the
        // window to the target % and auto-stops. UI just sends the target.
        var areas = ['lf', 'rf', 'lr', 'rr'];
        var rows = document.querySelectorAll('#panelWindows .vc-window-row[data-area]');
        for (var ri = 0; ri < rows.length; ri++) {
            (function(row) {
                var area = row.getAttribute('data-area');
                var areaNum = parseInt(row.getAttribute('data-area-num'), 10);
                var presets = row.querySelectorAll('.vc-preset');
                for (var pi = 0; pi < presets.length; pi++) {
                    (function(btn) {
                        btn.addEventListener('click', function() {
                            var target = parseInt(btn.getAttribute('data-preset'), 10);
                            var current = self.vehicleState.windows[area];
                            // VFX: only show direction if we know the current
                            // position; otherwise skip the animation (target
                            // alone doesn't tell us which way it'll move).
                            if (typeof current === 'number' && current >= 0) {
                                if (Math.abs(current - target) > 5) {
                                    self.triggerWindowVFX(area, target > current);
                                }
                            }
                            // Visually mark the chosen preset; live position
                            // tracking will reconcile this on the next state poll.
                            self.markWindowPreset(area, target);
                            self.apiPost('/api/vehicle/window',
                                { area: areaNum, targetPercent: target });
                        });
                    })(presets[pi]);
                }
            })(rows[ri]);
        }

        // All windows — only fully-open / fully-closed makes sense for "all"
        // (per-window % requires per-window polling, no SDK batch primitive).
        this.bindBtn('btnWinAllOpen', function() {
            for (var j = 0; j < areas.length; j++) self.triggerWindowVFX(areas[j], true);
            self.apiPost('/api/vehicle/window', { area: 0, command: 1 });
            self.toast('All windows opening', 'info');
        });
        this.bindBtn('btnWinAllClose', function() {
            for (var j = 0; j < areas.length; j++) self.triggerWindowVFX(areas[j], false);
            self.apiPost('/api/vehicle/window', { area: 0, command: 2 });
            self.toast('All windows closing', 'info');
        });

        // === CLIMATE CONTROLS ===
        this.bindBtn('btnAcOn', function() {
            // Blue burst from cabin center
            self.triggerSonarVFX(0, 0.6, 0.2, new THREE.Color(0x38BDF8));
            self.triggerSonarVFX(0, 0.6, -0.2, new THREE.Color(0x38BDF8));
            self.flashBodyColor(new THREE.Color(0x38BDF8), 0.1, 2, null);
            self.apiPost('/api/vehicle/climate', { action: 'power_on' }).then(function(r) {
                if (r.success && r.commandSuccess !== false) { self.vehicleState.acOn = true; self.updateClimateUI(); self.toast('AC On', 'success'); }
                else { self.toast(r.error || 'AC command failed', 'error'); }
            });
        });
        this.bindBtn('btnAcOff', function() {
            self.flashBodyColor(new THREE.Color(0x71717A), 0.15, 1, null);
            self.apiPost('/api/vehicle/climate', { action: 'power_off' }).then(function(r) {
                if (r.success && r.commandSuccess !== false) { self.vehicleState.acOn = false; self.updateClimateUI(); self.toast('AC Off', 'info'); }
                else { self.toast(r.error || 'AC command failed', 'error'); }
            });
        });
        this.bindBtn('btnTempUp', function() {
            var t = Math.min(33, self.vehicleState.acTemp + 1);
            self.vehicleState.acTemp = t;
            self.updateClimateUI();
            // Warm pulse for temp up
            self.triggerSonarVFX(0, 0.6, 0, new THREE.Color(t > 25 ? 0xFF6B35 : 0x38BDF8));
            self.apiPost('/api/vehicle/climate', { action: 'set_temp', zone: 1, temp: t });
        });
        this.bindBtn('btnTempDown', function() {
            var t = Math.max(17, self.vehicleState.acTemp - 1);
            self.vehicleState.acTemp = t;
            self.updateClimateUI();
            // Cool pulse for temp down
            self.triggerSonarVFX(0, 0.6, 0, new THREE.Color(t < 20 ? 0x38BDF8 : 0x00D4AA));
            self.apiPost('/api/vehicle/climate', { action: 'set_temp', zone: 1, temp: t });
        });
        this.bindBtn('btnFanUp', function() {
            var f = Math.min(7, self.vehicleState.acFan + 1);
            self.vehicleState.acFan = f;
            self.updateClimateUI();
            // Multiple sonar rings for higher fan — more rings = more wind
            for (var fi = 0; fi < Math.min(f, 3); fi++) {
                (function(delay) {
                    setTimeout(function() { self.triggerSonarVFX(0, 0.5, 0.3 - delay * 0.3, new THREE.Color(0x00D4AA)); }, delay * 80);
                })(fi);
            }
            self.apiPost('/api/vehicle/climate', { action: 'set_fan', fan: f });
        });
        this.bindBtn('btnFanDown', function() {
            var f = Math.max(1, self.vehicleState.acFan - 1);
            self.vehicleState.acFan = f;
            self.updateClimateUI();
            self.triggerSonarVFX(0, 0.5, 0, new THREE.Color(0x52525B));
            self.apiPost('/api/vehicle/climate', { action: 'set_fan', fan: f });
        });

        // Seat heating — cycles 0→1→2→0
        var seatPositions = {
            1: { x: 0.5, y: 0.4, z: 0.2 },   // driver
            2: { x: -0.5, y: 0.4, z: 0.2 }    // passenger
        };
        for (var si = 1; si <= 2; si++) {
            (function(pos) {
                self.bindBtn('btnSeatHeat' + pos, function() {
                    var cur = self.vehicleState.seatHeat[pos] || 0;
                    var next = (cur + 1) % 3;
                    self.vehicleState.seatHeat[pos] = next;
                    self.vehicleState.seatCool[pos] = 0;
                    self.updateSeatUI(pos);
                    self.updateSeatGlows();
                    // Heat VFX — warm sonar at seat, intensity scales with level
                    var sp = seatPositions[pos];
                    if (next > 0) {
                        var heatColor = next === 2 ? 0xFF4500 : 0xFF8C00;
                        self.triggerSonarVFX(sp.x, sp.y, sp.z, new THREE.Color(heatColor));
                        if (next === 2) {
                            setTimeout(function() { self.triggerSonarVFX(sp.x, sp.y + 0.2, sp.z, new THREE.Color(0xFF4500)); }, 120);
                        }
                        self.toast('Seat heat: ' + (next === 1 ? 'Low' : 'High'), 'success');
                    } else {
                        self.toast('Seat heat: Off', 'info');
                    }
                    self.apiPost('/api/vehicle/seat', { action: 'heating', position: pos, level: next });
                });
                self.bindBtn('btnSeatCool' + pos, function() {
                    var cur = self.vehicleState.seatCool[pos] || 0;
                    var next = (cur + 1) % 3;
                    self.vehicleState.seatCool[pos] = next;
                    self.vehicleState.seatHeat[pos] = 0;
                    self.updateSeatUI(pos);
                    self.updateSeatGlows();
                    // Cool VFX — blue sonar at seat
                    var sp = seatPositions[pos];
                    if (next > 0) {
                        var coolColor = next === 2 ? 0x00BFFF : 0x87CEEB;
                        self.triggerSonarVFX(sp.x, sp.y, sp.z, new THREE.Color(coolColor));
                        if (next === 2) {
                            setTimeout(function() { self.triggerSonarVFX(sp.x, sp.y + 0.2, sp.z, new THREE.Color(0x00BFFF)); }, 120);
                        }
                        self.toast('Seat cool: ' + (next === 1 ? 'Low' : 'High'), 'success');
                    } else {
                        self.toast('Seat cool: Off', 'info');
                    }
                    self.apiPost('/api/vehicle/seat', { action: 'ventilation', position: pos, level: next });
                });
            })(si);
        }
    },

    bindBtn: function(id, handler) {
        var el = document.getElementById(id);
        if (!el) return;
        // Android 7.1 WebView occasionally drops `click` after a touch sequence
        // (long-press cancellation, fast taps, gesture conflicts). Bind both and
        // de-duplicate via a 500ms guard so only one fire per real interaction.
        var lastFire = 0;
        function fire(e) {
            var now = Date.now();
            if (now - lastFire < 500) return;
            lastFire = now;
            try { handler.call(el, e); }
            catch (err) { console.error('[VC] handler error for #' + id + ':', err); }
        }
        el.addEventListener('click', fire);
        el.addEventListener('touchend', function(e) {
            // Suppress the synthetic click that follows touchend on Android,
            // and prevent double-fire from the dedupe window.
            e.preventDefault();
            fire(e);
        }, { passive: false });
    },

    setPending: function(id, pending) {
        var el = document.getElementById(id);
        if (!el) return;
        if (pending) {
            el.classList.add('pending');
        } else {
            el.classList.remove('pending');
        }
    },

    // ==================== STATE SYNC ====================

    startStateSync: function() {
        var self = this;
        this.fetchState();
        this.pollInterval = setInterval(function() { self.fetchState(); }, 3000);
    },

    fetchState: function() {
        var self = this;
        fetch('/api/vehicle/state').then(function(resp) {
            return resp.json();
        }).then(function(data) {
            if (!data.success) return;

            var wasLocked = self.vehicleState.locked;

            // Doors (lock status: 1=locked, 2=unlocked)
            if (data.doors) {
                var d = data.doors;
                self.vehicleState.doors = {
                    lf: d.lf || -1, rf: d.rf || -1,
                    lr: d.lr || -1, rr: d.rr || -1,
                    trunk: d.trunk || -1, hood: d.hood || -1
                };
                var overall = (d.overall !== undefined && d.overall !== null) ? d.overall : -1;
                if (overall === 1) {
                    self.vehicleState.locked = true;
                } else if (overall === 2) {
                    self.vehicleState.locked = false;
                } else {
                    // Unknown from CAN bus — keep last known state if we had one
                    // Only set to null if we never received a valid state
                    if (wasLocked === null) self.vehicleState.locked = null;
                    // else keep wasLocked (persist last known)
                }
            }

            // Windows
            if (data.windows) {
                var w = data.windows;
                self.vehicleState.windows = {
                    lf: w.lf >= 0 ? w.lf : 0,
                    rf: w.rf >= 0 ? w.rf : 0,
                    lr: w.lr >= 0 ? w.lr : 0,
                    rr: w.rr >= 0 ? w.rr : 0
                };
            }

            // Battery
            if (data.battery) {
                self.vehicleState.soc = data.battery.soc || 0;
                self.vehicleState.rangeKm = data.battery.rangeKm || data.battery.bodyworkRangeKm || 0;
            }

            // Climate
            if (data.climate) {
                if (data.climate.acOn !== undefined) self.vehicleState.acOn = data.climate.acOn;
                if (data.climate.fanLevel !== undefined && data.climate.fanLevel >= 1 && data.climate.fanLevel <= 7) {
                    self.vehicleState.acFan = data.climate.fanLevel;
                }
                if (data.climate.insideTempC !== undefined && data.climate.insideTempC > 0) {
                    // Use inside temp as display reference (actual set temp not available from state)
                }
            }

            // Update UI
            self.updateHUD();
            self.updateWindowBars();
            self.updateDoorIndicators();
            self.updateTrunkIndicator();
            self.updateWindowGlows();
            self.updateClimateUI();
            self.updateSeatGlows();
            self.updateTabIndicators();

        }).catch(function(e) {
            console.warn('[VC] State fetch error:', e);
        });
    },

    checkCloudStatus: function() {
        var self = this;
        fetch('/api/vehicle/cloud-status').then(function(resp) {
            return resp.json();
        }).then(function(data) {
            self.vehicleState.cloudConfigured = data.configured && data.verified;
            self.updateCloudIndicator();
        }).catch(function(e) {
            console.warn('[VC] Cloud status error:', e);
        });
    },

    // Polls the cloud lock state. The server endpoint:
    //   - returns the cached MQTT-derived lock state immediately,
    //   - kicks off a one-shot REST refresh in the background if the cache
    //     is stale (rate-limited server-side, so this is cheap to call).
    // Used as a fallback for the lock-state UI: the CAN bus often returns
    // "unknown" while the car is sleeping; the cloud knows the answer.
    requestCloudLockRefresh: function() {
        var self = this;
        fetch('/api/vehicle/cloud-lock').then(function(resp) {
            return resp.json();
        }).then(function(data) {
            if (!data || !data.success || !data.status) return;
            var s = data.status;
            // Prefer cloud lock state when CAN bus didn't give us a valid one.
            // CAN bus sets self.vehicleState.locked = true/false; null = no
            // valid reading yet. We only override null — if CAN said locked
            // or unlocked, trust it (it's a few hundred ms fresh vs MQTT's
            // potentially-minutes-old snapshot).
            if (self.vehicleState.locked === null || self.vehicleState.locked === undefined) {
                if (s.lockState === 'locked') {
                    self.vehicleState.locked = true;
                    self.updateHUD();
                    self.updateDoorIndicators();
                    self.updateTabIndicators();
                } else if (s.lockState === 'unlocked') {
                    self.vehicleState.locked = false;
                    self.updateHUD();
                    self.updateDoorIndicators();
                    self.updateTabIndicators();
                }
            }
        }).catch(function(e) {
            console.warn('[VC] Cloud lock refresh error:', e);
        });
    },

    // Background poller for the cloud lock state. The cloud snapshot is the
    // authoritative source while the car is sleeping (CAN returns -1 in
    // that mode). 30s is plenty — MQTT pushes events the moment the car
    // moves, this is just a heartbeat for the cold-cache case.
    startCloudLockSync: function() {
        var self = this;
        this.cloudLockInterval = setInterval(function() {
            self.requestCloudLockRefresh();
        }, 30 * 1000);
    },

    // ==================== CLOUD MODAL ====================

    initCloudModal: function() {
        var self = this;
        var dismissBtn = document.getElementById('cloudModalDismiss');
        if (dismissBtn) {
            dismissBtn.addEventListener('click', function() { self.hideCloudModal(); });
        }
        // Also dismiss on overlay click (outside the modal card)
        var overlay = document.getElementById('cloudModal');
        if (overlay) {
            overlay.addEventListener('click', function(e) {
                if (e.target === overlay) self.hideCloudModal();
            });
        }
    },

    /**
     * Guard for cloud-requiring actions.
     * Returns true if cloud is configured (action can proceed).
     * Returns false and shows modal if cloud is not configured.
     */
    requireCloud: function() {
        if (this.vehicleState.cloudConfigured) return true;
        this.showCloudModal();
        return false;
    },

    showCloudModal: function() {
        var overlay = document.getElementById('cloudModal');
        if (overlay) overlay.classList.add('visible');
    },

    hideCloudModal: function() {
        var overlay = document.getElementById('cloudModal');
        if (overlay) overlay.classList.remove('visible');
    },

    // ==================== UI UPDATES ====================

    updateHUD: function() {
        var socEl = document.getElementById('socValue');
        if (socEl) socEl.textContent = Math.round(this.vehicleState.soc) + '%';

        var socFill = document.getElementById('socFill');
        if (socFill) socFill.style.width = Math.min(100, Math.max(0, this.vehicleState.soc)) + '%';

        var rangeEl = document.getElementById('rangeValue');
        if (rangeEl) rangeEl.textContent = Math.round(this.vehicleState.rangeKm) + ' km';

        this.updateLockUI(this.vehicleState.locked);
    },

    updateLockUI: function(locked) {
        var lockBtn = document.getElementById('btnLock');
        var unlockBtn = document.getElementById('btnUnlock');
        var lockStatus = document.getElementById('lockStatus');

        // locked can be true, false, or null (unknown)
        if (lockBtn) { if (locked === true) lockBtn.classList.add('on'); else lockBtn.classList.remove('on'); }
        if (unlockBtn) { if (locked === false) unlockBtn.classList.add('on'); else unlockBtn.classList.remove('on'); }
        if (lockStatus) {
            lockStatus.textContent = locked === true ? 'Locked' : (locked === false ? 'Unlocked' : 'Unknown');
            var dot = lockStatus.previousElementSibling;
            if (dot) {
                dot.className = 'dot ' + (locked === true ? 'green' : (locked === false ? 'amber' : 'grey'));
            }
        }
    },

    updateWindowBars: function() {
        var areas = ['lf', 'rf', 'lr', 'rr'];
        for (var i = 0; i < areas.length; i++) {
            var area = areas[i];
            var fill = document.getElementById('winFill_' + area);
            var pct = document.getElementById('winPct_' + area);
            var label = document.getElementById('winLabel_' + area);
            var val = this.vehicleState.windows[area];
            var hasReading = (typeof val === 'number' && val >= 0);
            var display = hasReading ? val : 0;
            if (fill) fill.style.width = display + '%';
            if (pct) pct.textContent = display + '%';
            if (label) label.textContent = hasReading ? (val + '%') : '--%';
            // Reconcile the highlighted preset with the live position. Pick
            // the closest preset within the same ±5% tolerance the backend
            // uses to stop.
            if (hasReading) this.markWindowPresetFromActual(area, val);
        }
    },

    /** Visually mark one preset as the active target for a window. */
    markWindowPreset: function(area, target) {
        var row = document.querySelector('#panelWindows .vc-window-row[data-area="' + area + '"]');
        if (!row) return;
        var presets = row.querySelectorAll('.vc-preset');
        for (var i = 0; i < presets.length; i++) {
            var v = parseInt(presets[i].getAttribute('data-preset'), 10);
            if (v === target) presets[i].classList.add('active');
            else presets[i].classList.remove('active');
        }
    },

    /** Pick the closest preset to the live percentage and mark it active. */
    markWindowPresetFromActual: function(area, actual) {
        var presets = [0, 25, 50, 75, 100];
        var closest = presets[0];
        var bestDelta = Math.abs(actual - presets[0]);
        for (var i = 1; i < presets.length; i++) {
            var d = Math.abs(actual - presets[i]);
            if (d < bestDelta) { bestDelta = d; closest = presets[i]; }
        }
        // Only highlight if we're meaningfully near a preset (±10% of it)
        // — avoids confusingly lighting up "50" when window is at 35%.
        if (bestDelta <= 10) this.markWindowPreset(area, closest);
        else this.markWindowPreset(area, -1);
    },

    updateDoorIndicators: function() {
        var areas = ['lf', 'rf', 'lr', 'rr'];
        for (var i = 0; i < areas.length; i++) {
            var area = areas[i];
            var el = document.getElementById('doorState_' + area);
            if (!el) continue;
            var val = this.vehicleState.doors[area];
            if (val === 1) {
                el.textContent = '\uD83D\uDD12'; // locked
                el.title = 'Locked';
                this.removeStateGlow('door_' + area);
            } else if (val === 2) {
                el.textContent = '\uD83D\uDD13'; // unlocked
                el.title = 'Unlocked';
                this.setStateGlow('door_' + area, this.getDoorPosition(area), 0xF59E0B); // amber
            } else {
                el.textContent = '\u2014';
                el.title = 'Unknown';
                this.removeStateGlow('door_' + area);
            }
        }
    },

    /** Update persistent glow for trunk open state */
    updateTrunkIndicator: function() {
        // doorLockStatus[4] = trunk: 1=locked/closed, 2=unlocked/open
        var trunkVal = -1;
        if (this.vehicleState.doors && this.vehicleState.doors.trunk !== undefined) {
            trunkVal = this.vehicleState.doors.trunk;
        }
        if (trunkVal === 2) {
            this.setStateGlow('trunk', { x: 0, y: 0.8, z: -2.2 }, 0x00D4AA); // green glow
        } else {
            this.removeStateGlow('trunk');
        }
    },

    /** Update persistent glow for open windows */
    updateWindowGlows: function() {
        var areas = ['lf', 'rf', 'lr', 'rr'];
        for (var i = 0; i < areas.length; i++) {
            var area = areas[i];
            var pct = this.vehicleState.windows[area] || 0;
            if (pct > 10) {
                this.setStateGlow('win_' + area, this.getWindowPosition(area), 0x38BDF8); // blue
            } else {
                this.removeStateGlow('win_' + area);
            }
        }
    },

    getDoorPosition: function(area) {
        var positions = {
            lf: { x: 1.0, y: 0.6, z: 0.5 },
            rf: { x: -1.0, y: 0.6, z: 0.5 },
            lr: { x: 1.0, y: 0.6, z: -0.5 },
            rr: { x: -1.0, y: 0.6, z: -0.5 }
        };
        return positions[area] || { x: 0, y: 0.5, z: 0 };
    },

    getWindowPosition: function(area) {
        var positions = {
            lf: { x: 1.0, y: 0.9, z: 0.5 },
            rf: { x: -1.0, y: 0.9, z: 0.5 },
            lr: { x: 1.0, y: 0.9, z: -0.5 },
            rr: { x: -1.0, y: 0.9, z: -0.5 }
        };
        return positions[area] || { x: 0, y: 0.9, z: 0 };
    },

    /** Add or update a persistent glow indicator on the car */
    setStateGlow: function(key, pos, colorHex) {
        if (!this.carModel) return;
        this.removeStateGlow(key);

        // Glowing ring — much more visible than a point light
        var ringGeo = new THREE.RingGeometry(0.08, 0.14, 24);
        var ringMat = new THREE.MeshBasicMaterial({
            color: colorHex, side: THREE.DoubleSide,
            transparent: true, opacity: 0.85
        });
        var ring = new THREE.Mesh(ringGeo, ringMat);
        ring.position.set(pos.x, pos.y, pos.z);
        ring.rotation.x = Math.PI / 2;
        this.carModel.add(ring);

        // Point light for ambient glow on nearby surfaces
        var light = new THREE.PointLight(colorHex, 0.6, 2.5);
        light.position.set(pos.x, pos.y, pos.z);
        this.carModel.add(light);

        // Pulse animation on the ring
        gsap.to(ringMat, {
            opacity: 0.3, duration: 1,
            yoyo: true, repeat: -1, ease: 'sine.inOut'
        });

        this.stateGlows[key] = { ring: ring, light: light, geo: ringGeo, mat: ringMat };
    },

    /** Remove a persistent glow */
    removeStateGlow: function(key) {
        var glow = this.stateGlows[key];
        if (!glow) return;
        gsap.killTweensOf(glow.mat);
        if (this.carModel) {
            this.carModel.remove(glow.ring);
            this.carModel.remove(glow.light);
        }
        glow.geo.dispose();
        glow.mat.dispose();
        delete this.stateGlows[key];
    },

    updateCloudIndicator: function() {
        var textEl = document.getElementById('cloudStatusText');
        var pillEl = document.getElementById('cloudStatus');
        if (!pillEl) return;
        var dot = pillEl.querySelector('.dot');
        if (this.vehicleState.cloudConfigured) {
            if (dot) dot.className = 'dot green';
            if (textEl) textEl.textContent = 'Cloud Connected';
        } else {
            if (dot) dot.className = 'dot red';
            if (textEl) textEl.textContent = 'Cloud Not Configured';
        }
    },

    updateClimateUI: function() {
        var tempEl = document.getElementById('acTemp');
        if (tempEl) tempEl.textContent = this.vehicleState.acTemp + '\u00B0';

        var fanEl = document.getElementById('acFan');
        if (fanEl) fanEl.textContent = this.vehicleState.acFan;

        // AC On button highlights when AC is on; AC Off button highlights when AC
        // is off. Both stay visible \u2014 neither hides \u2014 so the user can always tap
        // the opposite state regardless of where the live state currently is.
        var btnOn = document.getElementById('btnAcOn');
        var btnOff = document.getElementById('btnAcOff');
        if (btnOn) { if (this.vehicleState.acOn) btnOn.classList.add('on'); else btnOn.classList.remove('on'); }
        if (btnOff) { if (!this.vehicleState.acOn) btnOff.classList.add('on'); else btnOff.classList.remove('on'); }

        if (this.vehicleState.acOn) {
            this.setStateGlow('ac', { x: 0, y: 0.5, z: 0.3 }, 0x38BDF8);
            this.startAcSonar();
        } else {
            this.removeStateGlow('ac');
            this.stopAcSonar();
        }
    },

    updateSeatUI: function(pos) {
        var heatBtn = document.getElementById('btnSeatHeat' + pos);
        var coolBtn = document.getElementById('btnSeatCool' + pos);
        var heatLvl = this.vehicleState.seatHeat[pos] || 0;
        var coolLvl = this.vehicleState.seatCool[pos] || 0;

        if (heatBtn) { if (heatLvl > 0) heatBtn.classList.add('on'); else heatBtn.classList.remove('on'); }
        if (coolBtn) { if (coolLvl > 0) coolBtn.classList.add('on'); else coolBtn.classList.remove('on'); }
    },

    updateSeatGlows: function() {
        var self = this;
        if (!this._seatSonarIntervals) this._seatSonarIntervals = {};
        if (!this._seatSonarMeshes) this._seatSonarMeshes = {};

        // Seat positions on the 3D model (approximate interior positions)
        var seatPositions = {
            1: { x: 0.5, y: 0.4, z: 0.2 },   // driver
            2: { x: -0.5, y: 0.4, z: 0.2 }    // passenger
        };

        for (var pos = 1; pos <= 2; pos++) {
            var heatLvl = this.vehicleState.seatHeat[pos] || 0;
            var coolLvl = this.vehicleState.seatCool[pos] || 0;
            var key = 'seat_' + pos;

            if (heatLvl > 0 || coolLvl > 0) {
                // Determine color
                var colorHex;
                if (heatLvl > 0) {
                    colorHex = heatLvl === 2 ? 0xFF4500 : 0xFF8C00;
                } else {
                    colorHex = coolLvl === 2 ? 0x00BFFF : 0x87CEEB;
                }

                // If already running with same color, skip
                if (this._seatSonarIntervals[key] && this._seatSonarIntervals[key].color === colorHex) continue;

                // Clear existing interval for this seat if any
                this._stopSeatSonar(key);

                var sp = seatPositions[pos];
                (function(seatKey, seatPos, seatColor) {
                    if (!self._seatSonarMeshes[seatKey]) self._seatSonarMeshes[seatKey] = [];

                    function spawnSeatRing() {
                        if (!self.carModel) return;
                        var ringGeo = new THREE.RingGeometry(0.08, 0.12, 24);
                        var ringMat = new THREE.MeshBasicMaterial({
                            color: seatColor,
                            side: THREE.DoubleSide,
                            transparent: true,
                            opacity: 0.8
                        });
                        var ring = new THREE.Mesh(ringGeo, ringMat);
                        ring.position.set(seatPos.x, seatPos.y, seatPos.z);
                        ring.rotation.x = Math.PI / 2;
                        self.carModel.add(ring);
                        self._seatSonarMeshes[seatKey].push(ring);

                        // Expand from scale 1 to 4 and fade out over 1 second
                        gsap.to(ring.scale, {
                            x: 4, y: 4, z: 4,
                            duration: 1,
                            ease: 'power2.out'
                        });
                        gsap.to(ringMat, {
                            opacity: 0,
                            duration: 1,
                            ease: 'power2.out',
                            onComplete: function() {
                                if (self.carModel) self.carModel.remove(ring);
                                ringGeo.dispose();
                                ringMat.dispose();
                                var meshes = self._seatSonarMeshes[seatKey];
                                if (meshes) {
                                    var idx = meshes.indexOf(ring);
                                    if (idx !== -1) meshes.splice(idx, 1);
                                }
                            }
                        });
                    }

                    spawnSeatRing();
                    var intervalId = setInterval(function() {
                        spawnSeatRing();
                    }, 1500);

                    self._seatSonarIntervals[seatKey] = { id: intervalId, color: seatColor };
                })(key, sp, colorHex);
            } else {
                // Seat is off — stop sonar
                this._stopSeatSonar(key);
            }
        }
    },

    /** Stop sonar for a specific seat and clean up meshes */
    _stopSeatSonar: function(key) {
        if (this._seatSonarIntervals && this._seatSonarIntervals[key]) {
            clearInterval(this._seatSonarIntervals[key].id);
            delete this._seatSonarIntervals[key];
        }
        if (this._seatSonarMeshes && this._seatSonarMeshes[key]) {
            var meshes = this._seatSonarMeshes[key];
            for (var i = 0; i < meshes.length; i++) {
                var mesh = meshes[i];
                gsap.killTweensOf(mesh.scale);
                gsap.killTweensOf(mesh.material);
                if (this.carModel) this.carModel.remove(mesh);
                mesh.geometry.dispose();
                mesh.material.dispose();
            }
            this._seatSonarMeshes[key] = [];
        }
        // Also remove the static glow
        this.removeStateGlow(key);
    },

    // ==================== 3D SURROUND VIEW ====================

    init3dButton: function() {
        var self = this;
        // Hide button if running inside app WebView (AndroidBridge is injected by WebViewFragment)
        if (window.AndroidBridge) {
            var btn = document.getElementById('btn3dView');
            if (btn) btn.style.display = 'none';
            return;
        }
        this.bindBtn('btn3dView', function() {
            if (self._3dViewActive) {
                self.stop3dView();
            } else {
                self.start3dView();
            }
        });
    },

    start3dView: function() {
        var self = this;
        this._3dViewActive = true;
        this._3dDecoderMode = null;  // 'webcodecs' or 'jmuxer'
        this._3dStreamConnected = false;
        var btn = document.getElementById('btn3dView');
        if (btn) btn.classList.add('on');

        // Timeout: if no stream data arrives within 8 seconds, show error and stop
        this._3dTimeout = setTimeout(function() {
            if (self._3dViewActive && !self._3dStreamConnected) {
                self.toast('No camera stream available', 'error');
                self.stop3dView();
            }
        }, 8000);

        // Set stream to mosaic view mode (0) and high quality before connecting
        // This ensures we get the full 4-camera mosaic, same as the live view page
        Promise.all([
            fetch('/api/stream/view/0'),
            fetch('/api/stream/quality/HIGH', { method: 'POST' })
        ]).then(function() {
            self._start3dStream();
        }).catch(function() {
            // Even if quality/view set fails, try to connect anyway
            self._start3dStream();
        });
    },

    _start3dStream: function() {
        var self = this;

        try {
            // Use SotaPlayer (WebCodecs) — same decoder as the live view page
            var hasSotaPlayer = (typeof SotaPlayer !== 'undefined') && SotaPlayer.isSupported();

            if (hasSotaPlayer) {
                // SotaPlayer path — renders to canvas, use CanvasTexture for Three.js
                this._3dDecoderMode = 'webcodecs';
                this._3dCanvas = document.createElement('canvas');
                this._3dCanvas.width = 1280;
                this._3dCanvas.height = 960;
                this._3dCanvas.style.display = 'none';
                document.body.appendChild(this._3dCanvas);

                var protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
                var wsUrl = protocol + '//' + window.location.host + '/ws';
                // Append JWT as ?token= so tunnels work (cookies stripped by
                // SameSite; browser WS API can't set Authorization header).
                if (typeof BYDAuth !== 'undefined') {
                    var wsToken = BYDAuth.getToken();
                    if (wsToken) wsUrl += '?token=' + encodeURIComponent(wsToken);
                }

                this._sotaPlayer = new SotaPlayer(this._3dCanvas, wsUrl);
                this._sotaPlayer.onConnected = function() {
                    console.log('[VC] 3D WebCodecs stream connected');
                    self._3dStreamConnected = true;
                    if (self._3dTimeout) { clearTimeout(self._3dTimeout); self._3dTimeout = null; }
                    self.toast('3D stream connected', 'success');
                };
                this._sotaPlayer.onFrame = function() {
                    // Mark texture as needing update on each decoded frame
                    if (self._videoTexture) self._videoTexture.needsUpdate = true;
                };
                this._sotaPlayer.onDisconnected = function() {
                    console.log('[VC] 3D WebCodecs stream disconnected');
                };
                this._sotaPlayer.onError = function(e) {
                    console.error('[VC] 3D WebCodecs error:', e);
                };
                this._sotaPlayer.start();

                // Build the bowl mesh + contact shadow
                this._createSurroundBowl();
                this._createContactShadow();

                // Hide ground grid — it conflicts with the surround view
                if (this._groundGrid) this._groundGrid.visible = false;

                // Camera lives well inside the bowl (R=8) so the surround
                // wraps around the user. Polar stays just above horizon so we
                // never look up at the cap or down through the floor.
                if (this.controls) {
                    this._savedPolarMin = this.controls.minPolarAngle;
                    this._savedPolarMax = this.controls.maxPolarAngle;
                    this._savedMinDistance = this.controls.minDistance;
                    this._savedMaxDistance = this.controls.maxDistance;
                    this.controls.minPolarAngle = Math.PI * 0.28;
                    this.controls.maxPolarAngle = Math.PI * 0.52;
                    this.controls.minDistance = 3.2;
                    this.controls.maxDistance = 6.5;
                    this.controls.autoRotate = false;
                }

            } else {
                console.error('[VC] No H.264 decoder available (need SotaPlayer + WebCodecs)');
                this.toast('3D view requires WebCodecs support', 'error');
                this._3dViewActive = false;
                var btn = document.getElementById('btn3dView');
                if (btn) btn.classList.remove('on');
                return;
            }
        } catch(e) {
            console.error('[VC] 3D view start error:', e);
            this.toast('3D view failed: ' + e.message, 'error');
        }

        this.toast('3D Surround View active', 'info');
    },

    /** Soft contact-shadow plane under the car. Tiny dark blob; gives the
     *  model "weight" so it doesn't look like it's floating above the bowl. */
    _createContactShadow: function() {
        if (!this.scene) return;
        // Procedural radial-gradient texture — no asset round-trip.
        var size = 256;
        var c = document.createElement('canvas');
        c.width = c.height = size;
        var cg = c.getContext('2d');
        var grad = cg.createRadialGradient(size/2, size/2, size*0.08, size/2, size/2, size*0.5);
        grad.addColorStop(0, 'rgba(0, 0, 0, 0.55)');
        grad.addColorStop(0.55, 'rgba(0, 0, 0, 0.18)');
        grad.addColorStop(1, 'rgba(0, 0, 0, 0)');
        cg.fillStyle = grad;
        cg.fillRect(0, 0, size, size);
        var tex = new THREE.CanvasTexture(c);
        tex.minFilter = THREE.LinearFilter;
        tex.magFilter = THREE.LinearFilter;

        var mat = new THREE.MeshBasicMaterial({
            map: tex,
            transparent: true,
            depthWrite: false
        });
        // Roughly car-shaped footprint: a bit wider lateral than longitudinal.
        var geo = new THREE.PlaneGeometry(2.6, 4.2);
        var mesh = new THREE.Mesh(geo, mat);
        mesh.rotation.x = -Math.PI / 2;
        mesh.position.y = -0.39;
        mesh.renderOrder = -1;
        this.scene.add(mesh);
        this._contactShadow = mesh;
    },

    stop3dView: function() {
        this._3dViewActive = false;
        this._3dStreamConnected = false;
        if (this._3dTimeout) { clearTimeout(this._3dTimeout); this._3dTimeout = null; }
        var btn = document.getElementById('btn3dView');
        if (btn) btn.classList.remove('on');

        // Stop SotaPlayer
        if (this._sotaPlayer) {
            this._sotaPlayer.stop();
            this._sotaPlayer = null;
        }

        // Remove canvas
        if (this._3dCanvas) {
            if (this._3dCanvas.parentNode) this._3dCanvas.parentNode.removeChild(this._3dCanvas);
            this._3dCanvas = null;
        }

        // Remove bowl mesh, legacy ground disc (no-op now), contact shadow.
        if (this._skySphere && this.scene) {
            this.scene.remove(this._skySphere);
            this._skySphere.geometry.dispose();
            this._skySphere.material.dispose();
            this._skySphere = null;
        }
        if (this._groundDisc && this.scene) {
            this.scene.remove(this._groundDisc);
            this._groundDisc.geometry.dispose();
            this._groundDisc.material.dispose();
            this._groundDisc = null;
        }
        if (this._contactShadow && this.scene) {
            this.scene.remove(this._contactShadow);
            this._contactShadow.geometry.dispose();
            if (this._contactShadow.material.map) this._contactShadow.material.map.dispose();
            this._contactShadow.material.dispose();
            this._contactShadow = null;
        }

        if (this._videoTexture) {
            this._videoTexture.dispose();
            this._videoTexture = null;
        }

        this._3dDecoderMode = null;

        // Restore ground grid
        if (this._groundGrid) this._groundGrid.visible = true;

        // Restore orbit constraints
        if (this.controls && this._savedPolarMin !== undefined) {
            this.controls.minPolarAngle = this._savedPolarMin;
            this.controls.maxPolarAngle = this._savedPolarMax;
            if (this._savedMinDistance !== undefined) {
                this.controls.minDistance = this._savedMinDistance;
            }
            if (this._savedMaxDistance !== undefined) {
                this.controls.maxDistance = this._savedMaxDistance;
            }
            this.controls.autoRotate = true;
        }

        // Restore stream quality to LOW (default for remote viewing)
        fetch('/api/stream/quality/LOW', { method: 'POST' }).catch(function() {});

        this.toast('3D View off', 'info');
    },

    /**
     * Surround geometry: a single curved bowl mesh (LatheGeometry) that
     * flows from under the car up to the horizon, with a fake-homography
     * ground projection on the lower bowl and a linear sky-fade on the
     * upper bowl. One mesh, one shader — no wall/floor seam.
     *
     * Mosaic layout (after THREE.CanvasTexture flipY=true):
     *   tex space    canvas    camera
     *   (0.0, 0.0)   BL        Front
     *   (0.5, 0.0)   BR        Right
     *   (0.0, 0.5)   TL        Rear
     *   (0.5, 0.5)   TR        Left
     *
     * Bearing: atan2(x, -z) → 0=front (-Z), +π/2=right (+X),
     *                          ±π=rear (+Z), -π/2=left (-X).
     *
     * Runtime knobs (set on VC and call stop3dView();start3dView(); to apply):
     *   _3dRotate        0..3   rotate camera assignment by 90° steps
     *   _3dSwapLR        bool   swap Left/Right cams
     *   _3dSwapFR        bool   swap Front/Rear cams
     *   _3dSideMirror    bool   horizontally flip side-camera images
     *   _3dRearMirror    bool   horizontally flip rear-camera image
     *   _3dFeather       0..0.5 seam blend half-width (fraction of one quadrant)
     *   _3dCropBottom    0..0.5 hide bottom N% of each cam (car body/wheel)
     *   _3dCropTop       0..0.5 hide top N% of each cam (warped sky)
     *   _3dFishStrength  0..1   fisheye-undistort strength (0 = none)
     */
    _createSurroundBowl: function() {
        if (!this.scene) return;

        if (this._3dCanvas) {
            this._videoTexture = new THREE.CanvasTexture(this._3dCanvas);
            this._videoTexture.minFilter = THREE.LinearFilter;
            this._videoTexture.magFilter = THREE.LinearFilter;
        } else {
            console.error('[VC] No canvas available for surround view');
            return;
        }

        // Defaults preserve the original production mapping (no flip / no swap).
        // Toggle these in the console + call VC.stop3dView();VC.start3dView();
        // to verify against the BYD camera-mount convention on your model.
        //   _3dRotate   0..3   rotate the world-bearing → camera mapping in 90° steps
        //   _3dSwapLR   bool   swap the Left and Right cameras
        //   _3dSwapFR   bool   swap the Front and Rear cameras
        //   _3dSideMirror  bool   horizontally flip both side-camera images
        //   _3dRearMirror  bool   horizontally flip the rear-camera image
        //   _3dFeather  0..0.5 seam blend half-width as a fraction of one quadrant
        if (this._3dSideMirror === undefined) this._3dSideMirror = false;
        if (this._3dRearMirror === undefined) this._3dRearMirror = false;
        // Default rotation 0: world bearing maps directly to camera index
        // with no offset (front-of-world → front cam).  The earlier
        // "everything looks swapped" symptom turned out to be a projection
        // artifact from the bowl + homography path, not a real swap.
        if (this._3dRotate     === undefined) this._3dRotate = 0;
        if (this._3dSwapLR     === undefined) this._3dSwapLR = false;
        if (this._3dSwapFR     === undefined) this._3dSwapFR = false;
        if (this._3dFeather    === undefined) this._3dFeather = 0.30;
        // Hide a thin sliver at the bottom (car body / wheel arch) and top
        // (warped sky).  Conservative defaults — raise per BYD model if
        // needed via VC._3dCropBottom / VC._3dCropTop.
        if (this._3dCropBottom === undefined) this._3dCropBottom = 0.15;
        if (this._3dCropTop    === undefined) this._3dCropTop = 0.08;
        // Generic radial fisheye undistortion strength — 0 = no undistort
        // (cheaper, what we had), 1 = full atan-style remap (visibly
        // straightens lane lines).  Default 0.6 hits a usable middle.
        if (this._3dFishStrength === undefined) this._3dFishStrength = 0.6;

        var WALL_RADIUS = 8.0;
        var WALL_HEIGHT = 5.0;
        var WALL_BOTTOM = -0.4;

        // GLSL fragment-shader fragment shared by wall + disc.  Defines
        // sampleSurround(bearing, vSample) and the helpers it needs.
        // Returns a vec4 where .a < 1.0 indicates the sample lies in the
        // cropped top/bottom of the cam (used to fade those areas out).
        var SHARED_GLSL = [
            'uniform sampler2D uTexture;',
            'uniform float uMirrorSides;',
            'uniform float uMirrorRear;',
            'uniform float uFeather;',
            'uniform int   uRotate;',
            'uniform float uSwapLR;',
            'uniform float uSwapFR;',
            'uniform float uCropBottom;',
            'uniform float uCropTop;',
            'uniform float uFishStrength;',
            '',
            'vec2 quadOrigin(int idx) {',
            '    if (idx == 0) return vec2(0.0, 0.0);',  // Front
            '    if (idx == 1) return vec2(0.5, 0.0);',  // Right
            '    if (idx == 2) return vec2(0.0, 0.5);',  // Rear
            '    return vec2(0.5, 0.5);',                // Left
            '}',
            '',
            'int remapIdx(int worldIdx) {',
            '    int idx = int(mod(float(worldIdx) + float(uRotate), 4.0));',
            '    if (uSwapLR > 0.5) {',
            '        if (idx == 1) idx = 3;',
            '        else if (idx == 3) idx = 1;',
            '    }',
            '    if (uSwapFR > 0.5) {',
            '        if (idx == 0) idx = 2;',
            '        else if (idx == 2) idx = 0;',
            '    }',
            '    return idx;',
            '}',
            '',
            '// Generic radial fisheye undistortion. Treats the cam frame',
            '// as a normalised (-1,-1)..(+1,+1) plane, computes the polar',
            '// radius r, and remaps it through an atan-style curve so',
            '// straight world lines (lane markings) come out straighter.',
            '// uFishStrength = 0 disables (returns input unchanged).',
            'vec2 undistort(vec2 xy) {',
            '    float r = length(xy);',
            '    if (r < 1e-4 || uFishStrength < 0.001) return xy;',
            '    // Approx fisheye half-FOV ~95° → tan(0.95) ≈ 1.40.',
            '    float k = 1.40;',
            '    // r_undist = tan(r * atan(k)) / k  — pulls peripheral',
            '    // pixels inward, straightening barrel curvature.',
            '    float rUndist = tan(r * atan(k)) / k;',
            '    float scale = mix(1.0, rUndist / r, uFishStrength);',
            '    return xy * scale;',
            '}',
            '',
            '// Returns the sampled cam color in .rgb plus a "valid" weight',
            '// in .a — 1.0 fully visible, fading to 0 at the cropped edges so',
            '// the caller can smoothly blend to the bowl background colour.',
            '// Crucially, even inside the crop band we still SAMPLE THE TEXTURE',
            '// (clamped to the kept range) — so the cropped strip reads as',
            '// "dimmed continuation of the cam image" rather than a hard black',
            '// rectangle.',
            'vec4 sampleAt(int worldIdx, float centeredOffset, float vSample) {',
            '    int idx = remapIdx(worldIdx);',
            '    vec2 qo = quadOrigin(idx);',
            '    float c = centeredOffset;',
            '    if (idx == 2 && uMirrorRear  > 0.5) c = -c;',
            '    if ((idx == 1 || idx == 3) && uMirrorSides > 0.5) c = -c;',
            '',
            '    // Build a normalised (-1,-1)..(+1,+1) coord inside this',
            '    // cam frame so undistort() can operate on a circular',
            '    // domain. After undistortion convert back to (u,v) in',
            '    // [0,1] within the quadrant.',
            '    vec2 nxy = vec2(c, vSample * 2.0 - 1.0);',
            '    nxy = undistort(nxy);',
            '    float localU = 0.5 + 0.5 * nxy.x;',
            '    float localV = 0.5 + 0.5 * nxy.y;',
            '',
            '    // Crop band: skip uCropBottom of the bottom (car body) and',
            '    // uCropTop of the top (warped sky).  We CLAMP the V into the',
            '    // kept range when sampling so the texture continues visually',
            '    // into the cropped edge (no abrupt black band), but emit an',
            '    // alpha that fades over a soft band so the caller can blend',
            '    // smoothly to the bowl background.',
            '    float vMin = uCropBottom;',
            '    float vMax = 1.0 - uCropTop;',
            '    // Sampling V — clamp into the visible band so cropped pixels',
            '    // read from the nearest valid row of the cam image.',
            '    float vSamp = clamp(localV, vMin, vMax);',
            '',
            '    // Alpha — soft fade across an inset band inside the crop edge',
            '    // so the transition into bg is gradual.  fadePx defines the',
            '    // soft-edge thickness inside both the bottom and top crops.',
            '    float fadePx = 0.06;',
            '    float bottomFade = smoothstep(vMin - fadePx, vMin + fadePx, localV);',
            '    float topFade    = smoothstep(vMax + fadePx, vMax - fadePx, localV);',
            '    float vMask = bottomFade * topFade;',
            '',
            '    // Reject samples fully outside the frame after undistortion.',
            '    float xMask = step(0.0, localU) * step(localU, 1.0);',
            '    float yMask = step(-fadePx, localV) * step(localV, 1.0 + fadePx);',
            '    float mask = vMask * xMask * yMask;',
            '',
            '    vec2 uv = vec2(qo.x + clamp(localU, 0.0, 1.0) * 0.5,',
            '                   qo.y + vSamp * 0.5);',
            '    vec4 col = texture2D(uTexture, uv);',
            '    col.a = mask;',
            '    return col;',
            '}',
            '',
            'vec4 sampleSurround(float bearing, float vSample) {',
            '    // Shift bearing by +π/4 so quadrants are CENTRED on the cardinal',
            '    // directions: bearing 0 (= world front) lands in the middle of',
            '    // the Front quadrant, +π/2 in the middle of Right, etc.',
            '    float b = mod(bearing + 0.78540, 6.28318);',
            '    if (b < 0.0) b += 6.28318;',
            '    float virtIdx = b / 1.5708;',           // 0..4
            '    float idxFloor = floor(virtIdx);',
            '    float frac = virtIdx - idxFloor;',       // 0..1 across one quadrant
            '    float centered = frac * 2.0 - 1.0;',     // -1..+1 across assigned quadrant
            '    float feather = uFeather;',
            '',
            '    int idxA = int(mod(idxFloor, 4.0));',
            '    vec4 colA = sampleAt(idxA, centered, vSample);',
            '',
            '    if (feather > 0.001 && frac < feather) {',
            '        int idxB = int(mod(idxFloor + 3.0, 4.0));',
            '        float centeredB = 1.0 + frac;',
            '        vec4 colB = sampleAt(idxB, centeredB, vSample);',
            '        float w = smoothstep(0.0, feather, frac);',
            '        return mix(colB, colA, w);',
            '    } else if (feather > 0.001 && frac > 1.0 - feather) {',
            '        int idxB = int(mod(idxFloor + 1.0, 4.0));',
            '        float centeredB = -1.0 + (frac - 1.0);',
            '        vec4 colB = sampleAt(idxB, centeredB, vSample);',
            '        float w = smoothstep(1.0, 1.0 - feather, frac);',
            '        return mix(colB, colA, w);',
            '    }',
            '    return colA;',
            '}',
            '',
            '// Helper: compose the surround sample against a dark background',
            '// so cropped/out-of-frame pixels fade smoothly to the bowl colour',
            '// instead of showing whatever happens to be in the texture there.',
            'vec3 composeSurround(vec3 surround_rgb, float alpha, vec3 bg) {',
            '    return mix(bg, surround_rgb, alpha);',
            '}'
        ].join('\n');

        var sharedUniforms = function() {
            return {
                uTexture:       { value: this._videoTexture },
                uMirrorSides:   { value: this._3dSideMirror ? 1.0 : 0.0 },
                uMirrorRear:    { value: this._3dRearMirror ? 1.0 : 0.0 },
                uFeather:       { value: this._3dFeather },
                uRotate:        { value: (this._3dRotate | 0) },
                uSwapLR:        { value: this._3dSwapLR ? 1.0 : 0.0 },
                uSwapFR:        { value: this._3dSwapFR ? 1.0 : 0.0 },
                uCropBottom:    { value: this._3dCropBottom },
                uCropTop:       { value: this._3dCropTop },
                uFishStrength:  { value: this._3dFishStrength }
            };
        }.bind(this);

        // ── Cylindrical wall ────────────────────────────────────────────
        var wallGeo = new THREE.CylinderGeometry(
            WALL_RADIUS, WALL_RADIUS, WALL_HEIGHT, 96, 1, true);
        wallGeo.translate(0, WALL_BOTTOM + WALL_HEIGHT / 2, 0);

        var wallMat = new THREE.ShaderMaterial({
            uniforms: sharedUniforms(),
            vertexShader: [
                'varying vec3 vWorldPos;',
                'varying float vYNorm;',
                'void main() {',
                '    vec4 wp = modelMatrix * vec4(position, 1.0);',
                '    vWorldPos = wp.xyz;',
                '    vYNorm = clamp((position.y - (' + WALL_BOTTOM.toFixed(2) + ')) / ' + WALL_HEIGHT.toFixed(2) + ', 0.0, 1.0);',
                '    gl_Position = projectionMatrix * viewMatrix * wp;',
                '}'
            ].join('\n'),
            fragmentShader: [
                'precision mediump float;',
                SHARED_GLSL,
                'varying vec3 vWorldPos;',
                'varying float vYNorm;',
                'void main() {',
                '    float bearing = atan(vWorldPos.x, -vWorldPos.z);',
                '    vec4 cam = sampleSurround(bearing, vYNorm);',
                '',
                '    // Build the local sky/bowl color used as the background.',
                '    vec3 horizon = vec3(0.04, 0.10, 0.11);',
                '    vec3 zenith  = vec3(0.01, 0.02, 0.03);',
                '    vec3 sky = mix(horizon, zenith, smoothstep(0.75, 1.0, vYNorm));',
                '    vec3 baseBg = mix(vec3(0.04, 0.04, 0.05), sky,',
                '                      smoothstep(0.0, 0.4, vYNorm));',
                '',
                '    // Cropped/out-of-frame fade — instead of mixing into a',
                '    // flat plate, blend toward a *darkened* version of the',
                '    // cam itself so the cropped strip reads as a softly',
                '    // dimmed continuation of the image rather than a black',
                '    // band.  cam.a → 0 at the crop edge, so we fade smoothly',
                '    // from full-bright cam to dim cam to bg.',
                '    vec3 dimmedCam = cam.rgb * 0.35;',
                '    vec3 fadeColor = mix(baseBg, dimmedCam, 0.6);',
                '    vec3 rgb = composeSurround(cam.rgb, cam.a, fadeColor);',
                '',
                '    // Normal sky fade — the upper bowl always dissolves to',
                '    // the gradient regardless of whether the cam is cropped.',
                '    float skyFade = smoothstep(0.65, 0.95, vYNorm);',
                '    rgb = mix(rgb, sky, skyFade);',
                '',
                '    float horizonGlow = smoothstep(0.55, 0.62, vYNorm) *',
                '                        smoothstep(0.72, 0.62, vYNorm);',
                '    rgb += vec3(0.0, 0.06, 0.05) * horizonGlow * 0.25;',
                '',
                '    float groundFade = smoothstep(0.05, 0.0, vYNorm);',
                '    rgb = mix(rgb, vec3(0.04, 0.04, 0.05), groundFade * 0.6);',
                '',
                '    gl_FragColor = vec4(rgb, 1.0);',
                '}'
            ].join('\n'),
            side: THREE.BackSide,
            depthWrite: false
        });
        var wall = new THREE.Mesh(wallGeo, wallMat);
        wall.renderOrder = -2;
        this.scene.add(wall);
        this._skySphere = wall;

        // ── Ground disc ─────────────────────────────────────────────────
        var groundGeo = new THREE.CircleGeometry(WALL_RADIUS * 0.95, 96);
        var groundMat = new THREE.ShaderMaterial({
            uniforms: sharedUniforms(),
            vertexShader: [
                'varying vec2 vLocal;',
                'void main() {',
                '    vLocal = position.xy;',
                '    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);',
                '}'
            ].join('\n'),
            fragmentShader: [
                'precision mediump float;',
                SHARED_GLSL,
                'varying vec2 vLocal;',
                'void main() {',
                '    float worldX = vLocal.x;',
                '    float worldZ = -vLocal.y;',
                '    float bearing = atan(worldX, -worldZ);',
                '    float r = length(vLocal) / ' + (WALL_RADIUS * 0.95).toFixed(2) + ';',
                '    float vSample = clamp(r * 0.5, 0.0, 0.5);',
                '    vec4 cam = sampleSurround(bearing, vSample);',
                '',
                '    // Same soft-fade strategy as the wall: cropped pixels',
                '    // ease into a darkened version of the cam itself.',
                '    vec3 baseBg = vec3(0.04, 0.04, 0.05);',
                '    vec3 dimmedCam = cam.rgb * 0.35;',
                '    vec3 fadeColor = mix(baseBg, dimmedCam, 0.6);',
                '    vec3 rgb = composeSurround(cam.rgb, cam.a, fadeColor);',
                '',
                '    float innerFade = smoothstep(0.05, 0.18, r);',
                '    float outerFade = smoothstep(1.0, 0.85, r);',
                '    float a = innerFade * outerFade;',
                '    rgb = mix(bg, rgb, a);',
                '    gl_FragColor = vec4(rgb, 1.0);',
                '}'
            ].join('\n'),
            side: THREE.DoubleSide,
            depthWrite: false
        });
        var disc = new THREE.Mesh(groundGeo, groundMat);
        disc.rotation.x = -Math.PI / 2;
        disc.position.y = WALL_BOTTOM;
        disc.renderOrder = -1;
        this.scene.add(disc);
        this._groundDisc = disc;
    },

    // ==================== API HELPERS ====================

    apiPost: function(url, body) {
        return fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: body ? JSON.stringify(body) : '{}'
        }).then(function(resp) {
            return resp.json();
        }).catch(function(e) {
            return { success: false, error: 'Network error: ' + e.message };
        });
    },

    toast: function(message, type) {
        var el = document.getElementById('vcToast');
        if (!el) return;
        el.textContent = message;
        el.className = 'vc-toast show ' + (type || 'info');
        clearTimeout(this._toastTimer);
        var toastEl = el;
        this._toastTimer = setTimeout(function() {
            toastEl.classList.remove('show');
        }, 2500);
    }
};

// Boot when DOM is ready
document.addEventListener('DOMContentLoaded', function() { VC.init(); });
