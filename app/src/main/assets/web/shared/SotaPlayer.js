/**
 * SOTA H.264 Player - In-Band Configuration Strategy
 * Glues SPS+PPS+IDR together as one "Super Chunk" for WebCodecs.
 */
(function(global) {
    class SotaPlayer {
        constructor(canvas, url) {
            if (typeof canvas === 'string') {
                this.canvas = document.getElementById(canvas);
            } else {
                this.canvas = canvas;
            }
            this.ctx = this.canvas.getContext('2d');
            this.url = url || null;
            this.ws = null;
            this.decoder = null;
            this.sps = null;
            this.pps = null;
            this.hasReceivedKeyframe = false;
            this.running = false;
            this.frameCount = 0;
            this.onConnected = null;
            this.onDisconnected = null;
            this.handleFrame = this.handleFrame.bind(this);
            this.handleError = this.handleError.bind(this);
        }

        static isSupported() {
            return "VideoDecoder" in window && "EncodedVideoChunk" in window;
        }

        toggle() {
            if (this.running) this.stop();
            else this.start();
            return this.running;
        }

        connect(url) {
            this.url = url;
            this.start();
        }

        start() {
            if (this.running) { this.stop(); return; }
            if (!SotaPlayer.isSupported()) { console.error("[SotaPlayer] WebCodecs not supported!"); return; }

            this.running = true;
            this.sps = null;
            this.pps = null;
            this.hasReceivedKeyframe = false;
            this.frameCount = 0;
            this.connectWebSocket();
        }

        connectWebSocket() {
            if (!this.url) return;
            this.ws = new WebSocket(this.url);
            this.ws.binaryType = "arraybuffer";

            this.ws.onopen = () => {
                this.initDecoder();
                if (this.onConnected) this.onConnected();
            };
            this.ws.onmessage = (e) => this.ingest(new Uint8Array(e.data));
            this.ws.onclose = () => {
                this.running = false;
                if (this.onDisconnected) this.onDisconnected();
            };
            this.ws.onerror = () => { this.running = false; };
        }

        initDecoder() {
            if (this.decoder) return;
            this.decoder = new VideoDecoder({
                output: this.handleFrame,
                error: this.handleError
            });
            this.decoder.configure({
                codec: "avc1.64001F",
                hardwareAcceleration: "prefer-hardware",
                optimizeForLatency: true
            });
        }

        ingest(data) {
            if (!this.running) return;
            const nalUnits = this.splitNALUnits(data);
            for (const nal of nalUnits) {
                this.processNAL(nal);
            }
        }

        splitNALUnits(data) {
            const units = [];
            let i = 0, lastStart = -1;

            while (i < data.length - 4) {
                if (data[i] === 0 && data[i+1] === 0) {
                    let startCodeLen = 0;
                    if (data[i+2] === 0 && data[i+3] === 1) startCodeLen = 4;
                    else if (data[i+2] === 1) startCodeLen = 3;

                    if (startCodeLen > 0) {
                        if (lastStart >= 0) units.push(data.slice(lastStart, i));
                        lastStart = i;
                        i += startCodeLen;
                        continue;
                    }
                }
                i++;
            }

            if (lastStart >= 0) units.push(data.slice(lastStart));
            else if (data.length > 0) units.push(data);
            return units;
        }

        processNAL(data) {
            let nalType = 0;
            if (data[0] === 0 && data[1] === 0 && data[2] === 0 && data[3] === 1) {
                nalType = data[4] & 0x1F;
            } else if (data[0] === 0 && data[1] === 0 && data[2] === 1) {
                nalType = data[3] & 0x1F;
            } else {
                return;
            }

            // Capture SPS/PPS — reconfigure decoder if SPS changes (quality switch)
            if (nalType === 7) {
                if (this.sps && !this.arraysEqual(this.sps, data)) {
                    // SPS changed (quality/resolution change) — reset decoder state
                    this.sps = data;
                    this.hasReceivedKeyframe = false;
                    if (this.decoder) {
                        try {
                            this.decoder.reset();
                            this.decoder.configure({
                                codec: "avc1.64001F",
                                hardwareAcceleration: "prefer-hardware",
                                optimizeForLatency: true
                            });
                        } catch (e) {}
                    }
                    return;
                }
                this.sps = data;
                return;
            }
            if (nalType === 8) { this.pps = data; return; }

            // Handle video frames
            if (nalType === 5 || nalType === 1) {
                if (nalType === 5 && !this.hasReceivedKeyframe) {
                    if (this.sps) {
                        const superFrame = this.buildSuperFrame(data);
                        this.decodeChunk(superFrame, true);
                        this.hasReceivedKeyframe = true;
                    }
                    return;
                }

                if (this.hasReceivedKeyframe) {
                    if (nalType === 5 && this.sps) {
                        this.decodeChunk(this.buildSuperFrame(data), true);
                    } else {
                        this.decodeChunk(data, false);
                    }
                }
            }
        }

        buildSuperFrame(idrData) {
            const spsLen = this.sps ? this.sps.length : 0;
            const ppsLen = this.pps ? this.pps.length : 0;
            const superFrame = new Uint8Array(spsLen + ppsLen + idrData.length);
            let offset = 0;
            if (this.sps) { superFrame.set(this.sps, offset); offset += spsLen; }
            if (this.pps) { superFrame.set(this.pps, offset); offset += ppsLen; }
            superFrame.set(idrData, offset);
            return superFrame;
        }

        decodeChunk(data, isKey) {
            try {
                const chunk = new EncodedVideoChunk({
                    type: isKey ? "key" : "delta",
                    timestamp: performance.now() * 1000,
                    data: data
                });
                this.decoder.decode(chunk);
            } catch (e) {}
        }

        handleFrame(frame) {
            if (!this.running) { frame.close(); return; }

            if (this.canvas.width !== frame.displayWidth || this.canvas.height !== frame.displayHeight) {
                this.canvas.width = frame.displayWidth;
                this.canvas.height = frame.displayHeight;
            }

            this.ctx.drawImage(frame, 0, 0, this.canvas.width, this.canvas.height);
            frame.close();
            this.frameCount++;
        }

        handleError(e) {
            if (this.decoder) {
                try {
                    this.decoder.reset();
                    this.decoder.configure({
                        codec: "avc1.64001F",
                        hardwareAcceleration: "prefer-hardware",
                        optimizeForLatency: true
                    });
                } catch (err) {}
            }
            this.hasReceivedKeyframe = false;
        }

        stop() {
            this.running = false;
            if (this.ws) { this.ws.close(); this.ws = null; }
            if (this.decoder) { try { this.decoder.close(); } catch(e) {} this.decoder = null; }
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
            this.sps = null;
            this.pps = null;
            this.hasReceivedKeyframe = false;
        }

        isRunning() { return this.running; }

        arraysEqual(a, b) {
            if (a.length !== b.length) return false;
            for (let i = 0; i < a.length; i++) {
                if (a[i] !== b[i]) return false;
            }
            return true;
        }
    }

    if (typeof module !== 'undefined' && module.exports) module.exports = SotaPlayer;
    else global.SotaPlayer = SotaPlayer;
})(window);
