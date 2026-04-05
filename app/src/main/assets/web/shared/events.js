/**
 * BYD Champ - Events Module
 * Calendar-based recording browser with video playback, pagination & thumbnails
 */

window.BYD = window.BYD || {};

BYD.events = {
    currentDate: new Date(),
    selectedDate: null,
    currentFilter: 'all',
    recordings: [],
    totalCount: 0,
    datesWithRecordings: new Map(),
    currentPage: 1,
    pageSize: 12,
    totalPages: 1,
    
    async init() {
        const urlParams = new URLSearchParams(window.location.search);
        const filterParam = urlParams.get('filter');
        if (filterParam && ['all', 'sentry', 'normal', 'proximity'].includes(filterParam)) {
            this.currentFilter = filterParam;
            document.querySelectorAll('.filter-tab').forEach(tab => {
                tab.classList.toggle('active', tab.dataset.filter === filterParam);
            });
        }
        
        this.renderCalendar();
        this.updateRecordingsTitle();
        this.updateCalendarButton();
        await this.loadDatesWithRecordings();
        await this.loadStorageStats();
        await this.loadRecordings();
        
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeVideo();
                this.closeCalendar();
            }
        });
        
        document.getElementById('videoModal').addEventListener('click', (e) => {
            if (e.target.id === 'videoModal') this.closeVideo();
        });
        
        document.getElementById('calendarPopup').addEventListener('click', (e) => {
            if (e.target.id === 'calendarPopup') this.closeCalendar();
        });
        
        const calendarPopup = document.getElementById('calendarPopup');
        const videoModal = document.getElementById('videoModal');
        
        const observer = new MutationObserver(() => {
            const isOpen = calendarPopup.classList.contains('active') || videoModal.classList.contains('active');
            document.body.style.overflow = isOpen ? 'hidden' : '';
        });
        
        observer.observe(calendarPopup, { attributes: true });
        observer.observe(videoModal, { attributes: true });
    },
    
    toggleCalendar() {
        document.getElementById('calendarPopup').classList.toggle('active');
    },
    
    closeCalendar() {
        document.getElementById('calendarPopup').classList.remove('active');
    },
    
    updateCalendarButton() {
        const btn = document.getElementById('calendarToggle');
        const text = document.getElementById('calendarBtnText');
        
        if (this.selectedDate) {
            const date = new Date(this.selectedDate + 'T00:00:00');
            text.textContent = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
            btn.classList.add('has-date');
        } else {
            text.textContent = 'Select Date';
            btn.classList.remove('has-date');
        }
    },
    
    renderCalendar() {
        const grid = document.getElementById('calendarGrid');
        const title = document.getElementById('calendarTitle');
        const year = this.currentDate.getFullYear();
        const month = this.currentDate.getMonth();
        
        const monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
                          'July', 'August', 'September', 'October', 'November', 'December'];
        title.textContent = monthNames[month] + ' ' + year;
        grid.innerHTML = '';
        
        ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].forEach(day => {
            const el = document.createElement('div');
            el.className = 'calendar-weekday';
            el.textContent = day;
            grid.appendChild(el);
        });
        
        const firstDay = new Date(year, month, 1).getDay();
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const daysInPrevMonth = new Date(year, month, 0).getDate();
        const todayStr = this.formatDateKey(new Date());
        
        for (let i = firstDay - 1; i >= 0; i--) {
            const day = daysInPrevMonth - i;
            this.addDayCell(grid, day, this.formatDateKey(new Date(year, month - 1, day)), true);
        }
        
        for (let day = 1; day <= daysInMonth; day++) {
            const dateKey = this.formatDateKey(new Date(year, month, day));
            this.addDayCell(grid, day, dateKey, false, dateKey === todayStr, this.selectedDate === dateKey);
        }
        
        const totalCells = grid.children.length;
        for (let day = 1; totalCells + day - 7 <= 42; day++) {
            this.addDayCell(grid, day, this.formatDateKey(new Date(year, month + 1, day)), true);
        }
    },
    
    addDayCell(grid, day, dateKey, isOtherMonth, isToday, isSelected) {
        const el = document.createElement('div');
        el.className = 'calendar-day';
        el.textContent = day;
        el.dataset.date = dateKey;
        
        if (isOtherMonth) el.classList.add('other-month');
        if (isToday) el.classList.add('today');
        if (isSelected) el.classList.add('selected');
        
        // Disable future dates
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const cellDate = new Date(dateKey + 'T00:00:00');
        const isFuture = cellDate > today;
        
        if (isFuture) {
            el.classList.add('disabled');
        } else {
            const dateInfo = this.datesWithRecordings.get(dateKey);
            if (dateInfo) {
                el.classList.add('has-recordings');
                if (dateInfo.hasSentry) el.classList.add('has-sentry');
            }
            el.addEventListener('click', () => this.selectDate(dateKey));
        }
        
        grid.appendChild(el);
    },
    
    formatDateKey(date) {
        return date.getFullYear() + '-' + 
               String(date.getMonth() + 1).padStart(2, '0') + '-' + 
               String(date.getDate()).padStart(2, '0');
    },
    
    prevMonth() {
        this.currentDate.setMonth(this.currentDate.getMonth() - 1);
        this.renderCalendar();
    },
    
    nextMonth() {
        this.currentDate.setMonth(this.currentDate.getMonth() + 1);
        this.renderCalendar();
    },
    
    selectDate(dateKey) {
        this.selectedDate = this.selectedDate === dateKey ? null : dateKey;
        document.querySelectorAll('.calendar-day').forEach(el => {
            el.classList.toggle('selected', el.dataset.date === this.selectedDate);
        });
        this.updateRecordingsTitle();
        this.updateCalendarButton();
        this.currentPage = 1;
        this.loadRecordings();
        this.closeCalendar();
    },
    
    setFilter(filter) {
        this.currentFilter = filter;
        document.querySelectorAll('.filter-tab').forEach(tab => {
            tab.classList.toggle('active', tab.dataset.filter === filter);
        });
        this.updateRecordingsTitle();
        this.currentPage = 1;
        this.loadRecordings();
    },
    
    updateRecordingsTitle() {
        const title = document.getElementById('recordingsTitle');
        let text = this.selectedDate 
            ? new Date(this.selectedDate + 'T00:00:00').toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
            : 'All';
        
        const suffixes = { sentry: ' Sentry Events', normal: ' Recordings', proximity: ' Proximity Events' };
        title.textContent = text + (suffixes[this.currentFilter] || ' Recordings');
    },
    
    updatePagination() {
        const pagination = document.getElementById('pagination');
        const prevBtn = document.getElementById('prevPageBtn');
        const nextBtn = document.getElementById('nextPageBtn');
        const info = document.getElementById('paginationInfo');
        
        if (this.totalPages <= 1) {
            pagination.style.display = 'none';
            return;
        }
        
        pagination.style.display = 'flex';
        prevBtn.disabled = this.currentPage <= 1;
        nextBtn.disabled = this.currentPage >= this.totalPages;
        info.textContent = 'Page ' + this.currentPage + ' of ' + this.totalPages;
    },
    
    prevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadRecordings();
            document.getElementById('recordingsList').scrollTop = 0;
        }
    },
    
    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadRecordings();
            document.getElementById('recordingsList').scrollTop = 0;
        }
    },

    async loadDatesWithRecordings() {
        try {
            const res = await fetch('/api/recordings/dates');
            const data = await res.json();
            if (data.success && data.dates) {
                this.datesWithRecordings.clear();
                data.dates.forEach(d => {
                    this.datesWithRecordings.set(d.date, { count: d.count, hasSentry: d.hasSentry });
                });
                this.renderCalendar();
            }
        } catch (e) {
            console.error('Failed to load dates:', e);
        }
    },
    
    async loadStorageStats() {
        try {
            const res = await fetch('/api/recordings/stats');
            const data = await res.json();
            if (data.success) {
                document.getElementById('storageUsed').textContent = data.totalSizeFormatted;
                const usedPercent = data.totalSpace > 0 ? (data.totalSize / data.totalSpace) * 100 : 0;
                document.getElementById('storageFill').style.width = Math.min(usedPercent, 100) + '%';
                document.getElementById('normalCount').textContent = data.normalCount || 0;
                document.getElementById('sentryCount').textContent = data.sentryCount || 0;
                document.getElementById('proximityCount').textContent = data.proximityCount || 0;
            }
        } catch (e) {
            console.error('Failed to load storage stats:', e);
        }
    },
    
    async loadRecordings() {
        const list = document.getElementById('recordingsList');
        list.innerHTML = '<div class="loading"><div class="spinner"></div></div>';
        
        try {
            let url = '/api/recordings';
            const params = [];
            if (this.currentFilter !== 'all') params.push('type=' + this.currentFilter);
            if (this.selectedDate) params.push('date=' + this.selectedDate);
            params.push('page=' + this.currentPage);
            params.push('pageSize=' + this.pageSize);
            url += '?' + params.join('&');
            
            const res = await fetch(url);
            const data = await res.json();
            
            if (data.success) {
                this.recordings = data.recordings || [];
                this.totalPages = data.totalPages || 1;
                this.totalCount = data.totalCount || this.recordings.length;
                this.renderRecordings();
                this.updatePagination();
                document.getElementById('recordingsCount').textContent = 
                    this.totalCount + ' video' + (this.totalCount !== 1 ? 's' : '');
            }
        } catch (e) {
            console.error('Failed to load recordings:', e);
            list.innerHTML = '<div class="empty-state"><svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg><div class="empty-title">Failed to load recordings</div><div class="empty-text">Check your connection and try again</div></div>';
        }
    },
    
    renderRecordings() {
        const list = document.getElementById('recordingsList');
        
        if (this.recordings.length === 0) {
            list.innerHTML = '<div class="empty-state"><svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="m22 8-6 4 6 4V8Z"/><rect width="14" height="12" x="2" y="6" rx="2"/></svg><div class="empty-title">No recordings found</div><div class="empty-text">Recordings will appear here when available</div></div>';
            return;
        }
        
        list.innerHTML = this.recordings.map(rec => {
            const thumbId = 'thumb-' + rec.filename.replace(/[^a-zA-Z0-9]/g, '_');
            const badge = rec.type === 'sentry' ? 'Sentry' : rec.type === 'proximity' ? 'Proximity' : 'Normal';
            const fname = rec.filename.length > 28 ? rec.filename.substring(0, 25) + '...' : rec.filename;
            
            // Start with placeholder, load thumbnail async
            return '<div class="recording-card" onclick="BYD.events.playVideo(\'' + rec.filename + '\')">' +
                '<div class="recording-thumbnail" id="' + thumbId + '" data-thumb="' + (rec.thumbnailUrl || '') + '">' +
                '<div class="thumb-placeholder"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="m22 8-6 4 6 4V8Z"/><rect width="14" height="12" x="2" y="6" rx="2"/></svg></div>' +
                '<div class="play-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="white"><polygon points="5 3 19 12 5 21 5 3"/></svg></div>' +
                (rec.duration ? '<span class="duration-badge">' + rec.duration + '</span>' : '') +
                '</div>' +
                '<div class="recording-info">' +
                '<div class="recording-name"><span class="recording-badge ' + rec.type + '">' + badge + '</span>' + fname + '</div>' +
                '<div class="recording-meta"><span>' + rec.dateFormatted + '</span><span>' + rec.timeFormatted + '</span><span>' + rec.sizeFormatted + '</span></div>' +
                '</div>' +
                '<div class="recording-actions">' +
                '<button class="action-btn" onclick="event.stopPropagation(); BYD.events.downloadVideo(\'' + rec.filename + '\')" title="Download"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg></button>' +
                '<button class="action-btn delete" onclick="event.stopPropagation(); BYD.events.deleteRecording(\'' + rec.filename + '\')" title="Delete"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg></button>' +
                '</div></div>';
        }).join('');
        
        // Load thumbnails async after render
        this.loadThumbnailsAsync();
    },
    
    // Load thumbnails asynchronously without blocking
    loadThumbnailsAsync() {
        document.querySelectorAll('.recording-thumbnail[data-thumb]').forEach(container => {
            const thumbUrl = container.dataset.thumb;
            if (!thumbUrl) return;
            
            this.loadSingleThumbnail(container, thumbUrl, 0);
        });
    },
    
    // Load single thumbnail with retry on 202
    loadSingleThumbnail(container, url, retryCount) {
        if (retryCount > 5) return; // Max 5 retries
        
        fetch(url).then(res => {
            if (res.status === 200) {
                return res.blob();
            } else if (res.status === 202) {
                // Generating, retry after delay
                setTimeout(() => this.loadSingleThumbnail(container, url, retryCount + 1), 1500);
                return null;
            }
            return null;
        }).then(blob => {
            if (blob && blob.size > 0) {
                const imgUrl = URL.createObjectURL(blob);
                const placeholder = container.querySelector('.thumb-placeholder');
                if (placeholder) {
                    const img = document.createElement('img');
                    img.src = imgUrl;
                    img.alt = 'Thumbnail';
                    img.onload = () => placeholder.remove();
                    img.onerror = () => URL.revokeObjectURL(imgUrl);
                    container.insertBefore(img, container.firstChild);
                }
            }
        }).catch(() => {});
    },
    
    onThumbError(el) {
        const container = el.parentElement;
        container.innerHTML = '<div class="thumb-placeholder"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="m22 8-6 4 6 4V8Z"/><rect width="14" height="12" x="2" y="6" rx="2"/></svg><span>No preview</span></div><div class="play-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="white"><polygon points="5 3 19 12 5 21 5 3"/></svg></div>';
    },
    
    playVideo(filename) {
        const rec = this.recordings.find(r => r.filename === filename);
        if (!rec) return;
        
        document.getElementById('videoTitle').textContent = rec.filename;
        document.getElementById('videoDate').innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg> ' + rec.dateFormatted;
        document.getElementById('videoTime').innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg> ' + rec.timeFormatted;
        document.getElementById('videoSize').innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg> ' + rec.sizeFormatted;
        
        const downloadBtn = document.getElementById('downloadBtn');
        downloadBtn.href = rec.videoUrl;
        downloadBtn.download = rec.filename;
        
        const player = document.getElementById('videoPlayer');
        player.setAttribute('playsinline', '');
        player.setAttribute('webkit-playsinline', '');
        player.src = rec.videoUrl;
        document.getElementById('videoModal').classList.add('active');
        player.load();
        player.oncanplay = function() { player.play().catch(function() {}); player.oncanplay = null; };
        
        // SOTA: Load event timeline for this recording
        this.loadTimeline(rec.filename, player);
    },
    
    closeVideo() {
        const player = document.getElementById('videoPlayer');
        player.pause();
        player.src = '';
        document.getElementById('videoModal').classList.remove('active');
        
        // SOTA: Clean up timeline
        this.destroyTimeline();
    },
    
    downloadVideo(filename) {
        const rec = this.recordings.find(r => r.filename === filename);
        if (!rec) return;
        const a = document.createElement('a');
        a.href = rec.videoUrl;
        a.download = rec.filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    },
    
    async deleteRecording(filename) {
        if (!confirm('Delete ' + filename + '?')) return;
        
        try {
            const res = await fetch('/api/recordings/' + filename, { method: 'DELETE' });
            const data = await res.json();
            
            if (data.success) {
                await this.loadDatesWithRecordings();
                await this.loadStorageStats();
                await this.loadRecordings();
                if (BYD.core && BYD.core.showToast) {
                    BYD.core.showToast('Recording deleted', 'success');
                }
            } else {
                alert('Failed to delete: ' + (data.error || 'Unknown error'));
            }
        } catch (e) {
            console.error('Delete failed:', e);
            alert('Failed to delete recording');
        }
    },
    
    // ========================================================================
    // SOTA: Event Timeline Scrubber
    // ========================================================================
    
    _timelineRaf: null,
    _timelineEvents: null,
    
    /**
     * Load event timeline data and render markers.
     * Backward compatible: if no JSON sidecar exists, timeline stays hidden.
     */
    async loadTimeline(filename, videoEl) {
        const scrubber = document.getElementById('timelineScrubber');
        const legend = document.getElementById('timelineLegend');
        const track = document.getElementById('timelineTrack');
        const playhead = document.getElementById('timelinePlayhead');
        
        // Guard: if timeline HTML elements don't exist (old cached page), skip silently
        if (!scrubber || !track || !playhead) return;
        
        // Reset
        track.innerHTML = '';
        playhead.style.left = '0px';
        scrubber.style.display = 'none';
        if (legend) legend.style.display = 'none';
        this._timelineEvents = null;
        
        try {
            const res = await fetch('/api/events/' + filename);
            const data = await res.json();
            
            if (!data.events || data.events.length === 0) {
                // No events — backward compatible, just hide the scrubber
                return;
            }
            
            this._timelineEvents = data;
            
            // Wait for video metadata to get duration
            const renderMarkers = () => {
                const duration = videoEl.duration;
                if (!duration || duration <= 0) return;
                
                const durationMs = data.durationMs > 0 ? data.durationMs : duration * 1000;
                
                track.innerHTML = '';
                
                for (const ev of data.events) {
                    const marker = document.createElement('div');
                    marker.className = 'timeline-marker type-' + ev.type;
                    
                    const leftPct = (ev.start / durationMs) * 100;
                    const widthPct = Math.max(((ev.end - ev.start) / durationMs) * 100, 0.5);
                    
                    marker.style.left = leftPct + '%';
                    marker.style.width = widthPct + '%';
                    track.appendChild(marker);
                }
                
                scrubber.style.display = 'block';
                if (legend) legend.style.display = 'flex';
            };
            
            if (videoEl.readyState >= 1) {
                renderMarkers();
            } else {
                videoEl.addEventListener('loadedmetadata', renderMarkers, { once: true });
            }
            
            // Click-to-seek on the timeline
            scrubber.onclick = (e) => {
                const rect = scrubber.getBoundingClientRect();
                const pct = (e.clientX - rect.left) / rect.width;
                if (videoEl.duration) {
                    videoEl.currentTime = pct * videoEl.duration;
                }
            };
            
            // Playhead tracking at 10 FPS (matches surveillance engine rate)
            const updatePlayhead = () => {
                if (!videoEl.paused && videoEl.duration > 0) {
                    const pct = (videoEl.currentTime / videoEl.duration) * 100;
                    playhead.style.left = pct + '%';
                }
                this._timelineRaf = requestAnimationFrame(updatePlayhead);
            };
            this._timelineRaf = requestAnimationFrame(updatePlayhead);
            
        } catch (e) {
            // Fetch failed — backward compatible, just hide
            console.debug('No timeline data for', filename);
        }
    },
    
    /**
     * Clean up timeline resources.
     */
    destroyTimeline() {
        if (this._timelineRaf) {
            cancelAnimationFrame(this._timelineRaf);
            this._timelineRaf = null;
        }
        this._timelineEvents = null;
        
        const scrubber = document.getElementById('timelineScrubber');
        const legend = document.getElementById('timelineLegend');
        if (scrubber) scrubber.style.display = 'none';
        if (legend) legend.style.display = 'none';
    }
};