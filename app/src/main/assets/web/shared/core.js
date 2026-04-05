/**
 * BYD Champ - Core Module
 * Shared utilities, status polling, and toast notifications
 */

window.BYD = window.BYD || {};

BYD.core = {
    deviceId: null,
    pollInterval: null,
    lastStatus: null,

    /**
     * Initialize core module
     */
    init() {
        this.startStatusPolling();
        this.startClock();
        console.log('[Core] Initialized');
    },

    /**
     * Start clock update (if element exists)
     */
    startClock() {
        const update = () => {
            const el = document.getElementById('currentTime');
            if (el) {
                el.textContent = new Date().toLocaleTimeString('en-US', { 
                    hour: '2-digit', 
                    minute: '2-digit', 
                    hour12: false 
                });
            }
        };
        update();
        setInterval(update, 1000);
    },

    /**
     * Start status polling
     */
    startStatusPolling() {
        this.refreshStatus();
        this.pollInterval = setInterval(() => this.refreshStatus(), 5000);
    },

    /**
     * Refresh status from server (consolidated - includes GPS)
     */
    async refreshStatus() {
        try {
            const res = await fetch('/status');
            const status = await res.json();
            this.lastStatus = status;

            // Device ID
            if (status.deviceId) {
                this.deviceId = status.deviceId;
                const el = document.getElementById('deviceId');
                if (el) el.textContent = status.deviceId;
            }

            // 12V Battery
            if (status.battery) {
                const el = document.getElementById('batteryValue');
                if (el) el.textContent = (status.battery.voltage || 0).toFixed(1) + 'V';
            }

            // ACC status
            const accEl = document.getElementById('accValue');
            if (accEl) {
                accEl.textContent = status.acc ? 'ON' : 'OFF';
                accEl.className = 'status-value ' + (status.acc ? 'on' : 'off');
            }

            // Surveillance status
            const survEl = document.getElementById('survStatus');
            if (survEl) {
                const active = status.gpuSurveillance || false;
                survEl.textContent = active ? 'ON' : 'OFF';
                survEl.className = 'status-value ' + (active ? 'on' : 'off');
            }

            // Connection dot
            const connDot = document.getElementById('connDot');
            if (connDot) {
                connDot.classList.add('connected');
            }

            // EV Battery SOC
            this.updateEvStatus(status);

            // GPS data is now in status.gps - notify map module if exists
            if (status.gps && BYD.map && BYD.map.updateFromStatus) {
                BYD.map.updateFromStatus(status.gps);
            }

            // Notify surveillance module if exists
            if (BYD.surveillance && BYD.surveillance.updateFromStatus) {
                BYD.surveillance.updateFromStatus(status);
            }

            return status;
        } catch (e) {
            console.error('[Core] Status refresh error:', e);
            // Remove connected indicator on error
            const connDot = document.getElementById('connDot');
            if (connDot) connDot.classList.remove('connected');
            return null;
        }
    },

    /**
     * Update EV battery and charging status - White rims with flow animation
     */
    updateEvStatus(status) {
        const evCard = document.getElementById('evCard');
        if (!evCard) return;

        // Get SOC percentage from status.soc.percent
        let soc = null;
        if (status.soc && status.soc.percent !== undefined) {
            soc = status.soc.percent;
        }

        // Update elements
        const evPercentValue = document.getElementById('evPercentValue');
        const evBatteryFill = document.getElementById('evBatteryFill');
        const evChargeFlow = document.getElementById('evChargeFlow');
        const evRange = document.getElementById('evRange');

        if (soc !== null) {
            const socRounded = Math.round(soc);
            
            // Update percentage text
            if (evPercentValue) {
                evPercentValue.textContent = `${socRounded}%`;
            }

            // Max Width = 120
            const maxBarWidth = 120;
            const currentWidth = maxBarWidth * (soc / 100);
            
            // Update BOTH the main bar and the flow overlay
            if (evBatteryFill) evBatteryFill.setAttribute('width', currentWidth);
            if (evChargeFlow) evChargeFlow.setAttribute('width', currentWidth);

            // Color Logic (Teal -> Cyan -> Blue)
            const gradStart = document.querySelector('.grad-start');
            const gradMid = document.querySelector('.grad-mid');
            const gradEnd = document.querySelector('.grad-end');
            if (gradStart && gradEnd) {
                if (soc <= 20) {
                    gradStart.setAttribute('stop-color', '#ef4444');
                    if (gradMid) gradMid.setAttribute('stop-color', '#dc2626');
                    gradEnd.setAttribute('stop-color', '#991b1b');
                } else if (soc <= 40) {
                    gradStart.setAttribute('stop-color', '#fbbf24');
                    if (gradMid) gradMid.setAttribute('stop-color', '#f59e0b');
                    gradEnd.setAttribute('stop-color', '#d97706');
                } else {
                    // SOTA Liquid Energy
                    gradStart.setAttribute('stop-color', '#2dd4bf');
                    if (gradMid) gradMid.setAttribute('stop-color', '#06b6d4');
                    gradEnd.setAttribute('stop-color', '#3b82f6');
                }
            }
        }

        // Update range from actual API data (electric range only)
        if (evRange) {
            if (status.range && status.range.elecRangeKm !== undefined) {
                // Use electric range from BYD API
                const rangeKm = status.range.elecRangeKm;
                evRange.textContent = rangeKm + ' km';
                
                // Add warning styling if range is low
                if (status.range.isCritical) {
                    evRange.classList.add('critical');
                    evRange.classList.remove('low');
                } else if (status.range.isLow) {
                    evRange.classList.add('low');
                    evRange.classList.remove('critical');
                } else {
                    evRange.classList.remove('low', 'critical');
                }
            } else if (soc !== null) {
                // Fallback: estimate range (~4km per %)
                const estimatedRange = Math.round(soc * 4);
                evRange.textContent = '~' + estimatedRange + ' km';
                evRange.classList.remove('low', 'critical');
            }
        }

        // Charging state
        const evPower = document.getElementById('evPower');
        const pattern = document.getElementById('chargeFlowPattern');

        let isCharging = false;
        let powerKW = 0;

        if (status.charging) {
            const stateName = status.charging.stateName || '';
            powerKW = status.charging.chargingPowerKW || 0;
            
            // Determine if actively charging
            const chargingStates = ['Charging', 'DC Charging', 'AC Charging', 'Fast Charging'];
            isCharging = chargingStates.some(s => stateName.toLowerCase().includes(s.toLowerCase())) || powerKW > 0;
        }

        // Update power display
        if (evPower) {
            if (isCharging) {
                // When charging is active, always show the power value (even 0.0 kW while ramping up)
                evPower.textContent = powerKW > 0 ? powerKW.toFixed(1) + ' kW' : '0.0 kW';
            } else {
                evPower.textContent = powerKW > 0 ? powerKW.toFixed(1) + ' kW' : '-- kW';
            }
        }

        // Charging Animation Logic
        if (isCharging) {
            evCard.classList.add('charging');
            // SOTA: Animate the pattern x position using requestAnimationFrame
            // This creates the "Moving Belt" effect left-to-right
            if (!evCard.dataset.animating) {
                evCard.dataset.animating = "true";
                let offset = 0;
                const animateFlow = () => {
                    if (!evCard.classList.contains('charging')) {
                        evCard.dataset.animating = "";
                        return;
                    }
                    offset -= 1; // Move left (creates rightward visual flow for stripes)
                    if (pattern) pattern.setAttribute('x', offset);
                    requestAnimationFrame(animateFlow);
                };
                requestAnimationFrame(animateFlow);
            }
        } else {
            evCard.classList.remove('charging');
        }

        // Personalized range from trip analytics
        this.updatePersonalizedRange();
    },

    /**
     * Fetch and display personalized range estimate from trip analytics
     */
    async updatePersonalizedRange() {
        const pRow = document.getElementById('evPersonalizedRow');
        const pVal = document.getElementById('evPersonalizedRange');
        if (!pRow || !pVal) return;

        // Only fetch once per session, cache the result
        if (this._personalizedRangeFetched) {
            if (this._personalizedRangeKm > 0) {
                pRow.style.display = 'flex';
                pVal.textContent = this._personalizedRangeKm + ' km';
            }
            return;
        }

        try {
            const resp = await fetch('/api/trips/range');
            const data = await resp.json();
            this._personalizedRangeFetched = true;
            if (data.success && data.range) {
                const predicted = Math.round(data.range.predictedRangeKm || data.range.predicted_range_km || 0);
                if (predicted > 0) {
                    this._personalizedRangeKm = predicted;
                    pRow.style.display = 'flex';
                    pVal.textContent = predicted + ' km';
                }
            }
        } catch (e) {
            this._personalizedRangeFetched = true;
        }
    },

    /**
     * Show toast notification
     */
    toast(message, type = 'info', duration = 3000) {
        const container = document.getElementById('toastContainer');
        if (!container) return;

        const toast = document.createElement('div');
        toast.className = 'toast ' + type;
        toast.textContent = message;
        container.appendChild(toast);

        setTimeout(() => {
            toast.style.animation = 'slideIn 0.4s ease reverse';
            setTimeout(() => toast.remove(), 400);
        }, duration);
    }
};

// Expose toast globally for convenience
BYD.utils = BYD.utils || {};
BYD.utils.toast = (msg, type) => BYD.core.toast(msg, type);
