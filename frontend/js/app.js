let riskGaugeChart = null;
let shapChart = null;
let riskHistoryChart = null;
let lastResult = null;
let authToken = null;
let sessionTimer = null;
let biasAuditData = null;
let riskHistory = []; // session-scoped risk trajectory (FR-09)
const SESSION_TIMEOUT_MS = 24 * 60 * 60 * 1000; // 24 hours

// ── Auth Functions ──

function showLogin() {
    document.getElementById('login-form-wrapper').style.display = 'block';
    document.getElementById('register-form-wrapper').style.display = 'none';
    clearAuthErrors();
}

function showRegister() {
    document.getElementById('login-form-wrapper').style.display = 'none';
    document.getElementById('register-form-wrapper').style.display = 'block';
    clearAuthErrors();
}

function clearAuthErrors() {
    document.getElementById('login-error').style.display = 'none';
    document.getElementById('register-error').style.display = 'none';
    document.getElementById('register-success').style.display = 'none';
}

function togglePassword(inputId, btn) {
    const input = document.getElementById(inputId);
    if (input.type === 'password') {
        input.type = 'text';
        btn.textContent = 'Hide';
    } else {
        input.type = 'password';
        btn.textContent = 'Show';
    }
}

document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('login-username').value.trim();
    const password = document.getElementById('login-password').value;
    const totpCode = document.getElementById('login-2fa-code') ? document.getElementById('login-2fa-code').value.trim() : null;

    const body = { username, password };
    if (totpCode) body.totp_code = totpCode;

    try {
        const res = await fetch('/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
        });
        const data = await res.json();

        if (res.ok && data.requires_2fa) {
            document.getElementById('login-2fa-group').style.display = 'block';
            document.getElementById('login-2fa-code').focus();
            document.getElementById('login-submit-btn').textContent = 'VERIFY & LOG IN';
            document.getElementById('login-error').style.display = 'none';
            return;
        }

        if (res.ok && data.token) {
            authToken = data.token;
            localStorage.setItem('careattend_token', data.token);
            localStorage.setItem('careattend_user', username);
            document.getElementById('login-2fa-group').style.display = 'none';
            if (document.getElementById('login-2fa-code')) document.getElementById('login-2fa-code').value = '';
            document.getElementById('login-submit-btn').textContent = 'LOG IN';
            showMainApp(username);
        } else {
            showAuthError('login-error', data.error || 'Login failed');
        }
    } catch {
        showAuthError('login-error', 'Connection error. Is the server running?');
    }
});

document.getElementById('register-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('reg-username').value.trim();
    const email = document.getElementById('reg-email').value.trim();
    const password = document.getElementById('reg-password').value;
    const role = document.getElementById('reg-role').value;

    try {
        const res = await fetch('/auth/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, email, password, role }),
        });
        const data = await res.json();

        if (res.ok) {
            document.getElementById('register-success').textContent = 'Account created. You can now log in.';
            document.getElementById('register-success').style.display = 'block';
            document.getElementById('register-error').style.display = 'none';
            setTimeout(showLogin, 1500);
        } else {
            showAuthError('register-error', data.error || 'Registration failed');
        }
    } catch {
        showAuthError('register-error', 'Connection error. Is the server running?');
    }
});

function showAuthError(elementId, message) {
    const el = document.getElementById(elementId);
    el.textContent = message;
    el.style.display = 'block';
}

let currentUsername = '';

function showMainApp(username) {
    currentUsername = username;
    const loginScreen = document.getElementById('login-screen');
    loginScreen.classList.add('fade-out');
    setTimeout(() => {
        loginScreen.style.display = 'none';
        loginScreen.classList.remove('fade-out');
        document.getElementById('main-app').style.display = 'block';
        const initials = username.substring(0, 2).toUpperCase();
        document.getElementById('user-badge').textContent = initials + ' ' + username;
        resetSessionTimer();
    }, 300);
}

async function openProfile() {
    document.getElementById('profile-overlay').style.display = 'flex';
    const initials = currentUsername.substring(0, 2).toUpperCase();
    document.getElementById('ac-avatar').textContent = initials;

    try {
        const res = await fetch('/api/profile', { headers: authHeaders() });
        if (res.ok) {
            const profile = await res.json();
            renderAccountCentre(profile);
        }
    } catch { /* use defaults */ }
}

function renderAccountCentre(profile) {
    document.getElementById('ac-display-name').textContent = profile.displayName || profile.username;
    document.getElementById('ac-role').textContent = profile.role;
    document.getElementById('ac-username').textContent = profile.username;
    document.getElementById('ac-email').textContent = profile.email;
    document.getElementById('ac-role-text').textContent = profile.role.charAt(0).toUpperCase() + profile.role.slice(1);
    document.getElementById('ac-edit-name').value = profile.displayName || '';

    if (profile.createdAt) {
        const d = new Date(profile.createdAt * 1000);
        document.getElementById('ac-member-since').textContent = d.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
    }

    if (profile.lastPasswordChange) {
        const d = new Date(profile.lastPasswordChange * 1000);
        document.getElementById('ac-pw-changed').textContent = 'Last changed: ' + d.toLocaleDateString('en-GB');
    } else {
        document.getElementById('ac-pw-changed').textContent = 'Never changed';
    }

    // 2FA status
    const badge = document.getElementById('2fa-badge');
    if (profile.totpEnabled) {
        badge.className = 'ac-2fa-badge enabled';
        badge.innerHTML = '&#128274; Enabled';
        document.getElementById('2fa-setup-area').style.display = 'none';
        document.getElementById('2fa-qr-area').style.display = 'none';
        document.getElementById('2fa-disable-area').style.display = 'block';
    } else {
        badge.className = 'ac-2fa-badge disabled';
        badge.innerHTML = '&#128274; Disabled';
        document.getElementById('2fa-setup-area').style.display = 'block';
        document.getElementById('2fa-qr-area').style.display = 'none';
        document.getElementById('2fa-disable-area').style.display = 'none';
    }
}

function switchAccountTab(tab) {
    document.querySelectorAll('.ac-tab').forEach(function(t) { t.classList.remove('active'); });
    document.querySelectorAll('.ac-panel').forEach(function(p) { p.classList.remove('active'); });
    document.querySelector('.ac-tab[onclick*="' + tab + '"]').classList.add('active');
    document.getElementById('ac-panel-' + tab).classList.add('active');
}

async function saveDisplayName() {
    const name = document.getElementById('ac-edit-name').value.trim();
    try {
        const res = await fetch('/api/profile', {
            method: 'PUT',
            headers: authHeaders(),
            body: JSON.stringify({ displayName: name }),
        });
        if (res.ok) {
            const profile = await res.json();
            document.getElementById('ac-display-name').textContent = profile.displayName || profile.username;
            alert('Display name updated.');
        }
    } catch {
        alert('Failed to update name.');
    }
}

async function handleChangePassword(e) {
    e.preventDefault();
    const currentPw = document.getElementById('ac-current-pw').value;
    const newPw = document.getElementById('ac-new-pw').value;
    const confirmPw = document.getElementById('ac-confirm-pw').value;

    if (newPw !== confirmPw) {
        alert('New passwords do not match.');
        return;
    }

    try {
        const res = await fetch('/api/profile/change-password', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ currentPassword: currentPw, newPassword: newPw }),
        });
        const data = await res.json();
        if (res.ok) {
            alert('Password changed successfully.');
            document.getElementById('change-password-form').reset();
            document.getElementById('ac-pw-changed').textContent = 'Last changed: ' + new Date().toLocaleDateString('en-GB');
        } else {
            alert(data.error || 'Password change failed.');
        }
    } catch {
        alert('Failed to change password.');
    }
}

function closeProfile() {
    document.getElementById('profile-overlay').style.display = 'none';
}

async function handleLogout() {
    try {
        await fetch('/auth/logout', {
            method: 'POST',
            headers: authHeaders(),
        });
    } catch { /* ignore */ }
    authToken = null;
    localStorage.removeItem('careattend_token');
    localStorage.removeItem('careattend_user');
    clearSessionTimer();
    closeProfile();
    document.getElementById('main-app').style.display = 'none';
    document.getElementById('login-screen').style.display = 'flex';
    document.getElementById('login-password').value = '';
    lastResult = null;
    showLogin();
}

function authHeaders() {
    const headers = { 'Content-Type': 'application/json' };
    if (authToken) headers['Authorization'] = `Bearer ${authToken}`;
    return headers;
}

// ── Session Timeout (NFR-06: 30min inactivity) ──

function resetSessionTimer() {
    clearSessionTimer();
    sessionTimer = setTimeout(() => {
        alert('Session expired due to inactivity.');
        handleLogout();
    }, SESSION_TIMEOUT_MS);
}

function clearSessionTimer() {
    if (sessionTimer) {
        clearTimeout(sessionTimer);
        sessionTimer = null;
    }
}

['click', 'keydown', 'mousemove', 'scroll'].forEach(event => {
    document.addEventListener(event, () => {
        if (authToken) resetSessionTimer();
    }, { passive: true });
});

// ── Tab Navigation ──

document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

function switchTab(tabName) {
    document.querySelectorAll('.tab-btn').forEach(b => {
        b.classList.remove('active');
        b.setAttribute('aria-selected', 'false');
    });
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
    const tabBtn = document.querySelector(`.tab-btn[data-tab="${tabName}"]`);
    if (tabBtn) {
        tabBtn.classList.add('active');
        tabBtn.setAttribute('aria-selected', 'true');
    }
    document.getElementById(`tab-${tabName}`).classList.add('active');
}

// ── Bias Tab Navigation ──

function switchBiasTab(tab) {
    document.querySelectorAll('.bias-tab').forEach(b => b.classList.remove('active'));
    document.querySelector(`[data-bias="${tab}"]`).classList.add('active');
    ['age', 'gender', 'imd'].forEach(t => {
        document.getElementById(`bias-${t}-panel`).style.display = t === tab ? 'block' : 'none';
    });
}

// ── Age Group Auto-calculation (FR-06) ──

document.getElementById('age').addEventListener('input', () => {
    const age = parseInt(document.getElementById('age').value);
    const display = document.getElementById('age-group-display');
    const label = document.getElementById('age-group-label');
    if (!isNaN(age) && age >= 0 && age <= 120) {
        let group;
        if (age < 18) group = 'Under 18';
        else if (age < 65) group = '18-64';
        else if (age < 75) group = '65-74';
        else if (age < 85) group = '75-84';
        else group = '85+';
        label.textContent = `Age Group: ${group} (auto-calculated)`;
        display.style.display = 'block';
    } else {
        display.style.display = 'none';
    }
});

// ── Form Submission ──

document.getElementById('assessment-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    const btn = document.getElementById('submit-btn');
    btn.disabled = true;
    btn.querySelector('.btn-text').style.display = 'none';
    btn.querySelector('.btn-loading').style.display = 'inline';

    const data = {
        Age: parseInt(document.getElementById('age').value),
        Gender: parseInt(document.getElementById('gender').value),
        AppointmentLeadTimeDays: parseInt(document.getElementById('leadtime').value),
        SMSReceived: document.getElementById('sms-check').checked ? 1 : 0,
        PriorDNACount: parseInt(document.getElementById('priordna').value),
        Hypertension: document.getElementById('hypertension').checked ? 1 : 0,
        Diabetes: document.getElementById('diabetes').checked ? 1 : 0,
        Alcoholism: document.getElementById('alcoholism').checked ? 1 : 0,
        Disability: document.getElementById('disability').checked ? 1 : 0,
        IMDDecile: parseInt(document.getElementById('imd').value),
    };

    try {
        const res = await fetch('/api/predict', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify(data),
        });
        const result = await res.json();

        if (res.ok) {
            lastResult = result;
            renderResults(result);
            switchTab('results');
        } else if (res.status === 401) {
            alert('Session expired. Please log in again.');
            handleLogout();
        } else {
            alert(result.error || 'Prediction failed.');
        }
    } catch {
        alert('Connection error. Is the server running?');
    } finally {
        btn.disabled = false;
        btn.querySelector('.btn-text').style.display = 'inline';
        btn.querySelector('.btn-loading').style.display = 'none';
    }
});

function validateForm() {
    let valid = true;
    const age = parseInt(document.getElementById('age').value);
    const imd = parseInt(document.getElementById('imd').value);

    document.getElementById('age-error').textContent = '';
    document.getElementById('imd-error').textContent = '';
    document.getElementById('age').classList.remove('invalid');
    document.getElementById('imd').classList.remove('invalid');

    if (isNaN(age) || age < 0 || age > 120) {
        document.getElementById('age-error').textContent = 'Age must be between 0 and 120';
        document.getElementById('age').classList.add('invalid');
        valid = false;
    }
    if (isNaN(imd) || imd < 1 || imd > 10) {
        document.getElementById('imd-error').textContent = 'IMD Decile must be between 1 and 10';
        document.getElementById('imd').classList.add('invalid');
        valid = false;
    }

    const status = document.getElementById('validation-status');
    status.textContent = valid ? 'All fields valid' : 'Please correct errors above';
    status.className = 'validation-status ' + (valid ? 'valid' : 'invalid');

    return valid;
}

// ── Render Results ──

function renderResults(result) {
    document.getElementById('no-results').style.display = 'none';
    document.getElementById('results-content').style.display = 'block';

    const tier = result.risk_tier.toLowerCase();
    const card = document.getElementById('risk-card');
    card.className = `card risk-card tier-${tier}`;

    // Session bar
    const sessionBar = document.getElementById('result-session-bar');
    const sessionId = result.sessionId ? result.sessionId.substring(0, 6).toUpperCase() : '---';
    sessionBar.innerHTML = `Session: #${sessionId} | Age Group: ${result.age_group}`;

    document.getElementById('risk-percentage').textContent = result.percentage + '%';

    const badge = document.getElementById('risk-tier-badge');
    badge.textContent = result.risk_tier.toUpperCase() + ' RISK';
    badge.className = `risk-tier-badge tier-${tier}`;

    const p = result.patient_summary;
    document.getElementById('patient-meta').innerHTML = `
        <span>Age: ${p.Age}</span>
        <span>Group: ${result.age_group}</span>
        <span>Gender: ${p.Gender === 1 ? 'Male' : 'Female'}</span>
        <span>IMD: ${p.IMDDecile}</span>
        <span>Lead Time: ${p.AppointmentLeadTimeDays}d</span>
        <span>Prior DNAs: ${p.PriorDNACount}</span>
    `;

    renderGauge(result.percentage, tier);
    renderShapChart(result.shap_values);
    renderInterventions(result.interventions);

    // NL summary display (Feature 13)
    if (result.nl_summary) {
        document.getElementById('nl-summary-card').style.display = 'block';
        document.getElementById('nl-summary-text').textContent = result.nl_summary;
    }

    // Feedback card
    document.getElementById('feedback-card').style.display = 'block';
    document.getElementById('feedback-response').style.display = 'none';

    // Risk history tracking (FR-09)
    riskHistory.push({
        time: new Date().toLocaleTimeString(),
        percentage: result.percentage,
        tier: result.risk_tier,
        age: p.Age,
    });
    if (riskHistory.length > 1) renderRiskHistory();
}

function renderGauge(percentage, tier) {
    const canvas = document.getElementById('risk-gauge');
    if (riskGaugeChart) riskGaugeChart.destroy();

    const colors = { low: '#007F3B', medium: '#FFB81C', high: '#DA291C' };
    const bgColors = { low: '#E8F5E9', medium: '#FFF8E1', high: '#FFEBEE' };

    riskGaugeChart = new Chart(canvas, {
        type: 'doughnut',
        data: {
            datasets: [{
                data: [percentage, 100 - percentage],
                backgroundColor: [colors[tier], bgColors[tier]],
                borderWidth: 0,
                circumference: 270,
                rotation: 225,
            }]
        },
        options: {
            responsive: false,
            cutout: '78%',
            plugins: { legend: { display: false }, tooltip: { enabled: false } },
        }
    });
}

function renderShapChart(shapValues) {
    const canvas = document.getElementById('shap-chart');
    if (shapChart) shapChart.destroy();

    const top = shapValues.slice(0, 5);
    const labels = top.map(s => s.label);
    const values = top.map(s => s.value);
    const bgColors = values.map(v => v > 0 ? 'rgba(218,41,28,0.75)' : 'rgba(0,127,59,0.75)');
    const borderColors = values.map(v => v > 0 ? '#DA291C' : '#007F3B');

    shapChart = new Chart(canvas, {
        type: 'bar',
        data: {
            labels,
            datasets: [{
                data: values,
                backgroundColor: bgColors,
                borderColor: borderColors,
                borderWidth: 1,
                borderRadius: 4,
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: (ctx) => {
                            const v = ctx.raw;
                            return v > 0 ? `+${v.toFixed(4)} (Increases Risk)` : `${v.toFixed(4)} (Reduces Risk)`;
                        }
                    }
                }
            },
            scales: {
                x: {
                    title: { display: true, text: 'SHAP Value (impact on prediction)', font: { size: 12 } },
                    grid: { color: '#F0F4F5' },
                },
                y: {
                    grid: { display: false },
                    ticks: { font: { size: 13, weight: '600' } },
                }
            }
        }
    });
}

const ICONS = {
    phone: '&#128222;', car: '&#128663;', users: '&#128101;',
    alert: '&#9888;', message: '&#128172;', accessibility: '&#9855;',
    heart: '&#10084;', calendar: '&#128197;',
};

const PRIORITY_COLORS = {
    1: '#DA291C', 2: '#FFB81C', 3: '#007F3B',
};

function renderInterventions(interventions) {
    const container = document.getElementById('interventions-list');
    container.innerHTML = interventions.map((iv, i) => `
        <div class="intervention-card priority-${iv.priority}">
            <div class="intervention-number" style="background:${PRIORITY_COLORS[iv.priority] || '#003087'}">${i + 1}</div>
            <div class="intervention-text">
                <h4>${iv.title}</h4>
                <p>${iv.description}</p>
            </div>
        </div>
    `).join('');
}

// ── Bias Audit ──

async function runBiasAudit() {
    const btn = document.getElementById('run-audit-btn');
    btn.disabled = true;
    btn.querySelector('.btn-text').style.display = 'none';
    btn.querySelector('.btn-loading').style.display = 'inline';

    try {
        const res = await fetch('/api/bias-audit', { headers: authHeaders() });
        if (res.status === 401) {
            alert('Session expired. Please log in again.');
            handleLogout();
            return;
        }
        const data = await res.json();
        renderBiasResults(data);
        document.getElementById('bias-results').style.display = 'block';
    } catch {
        alert('Bias audit failed. Is the server running?');
    } finally {
        btn.disabled = false;
        btn.querySelector('.btn-text').style.display = 'inline';
        btn.querySelector('.btn-loading').style.display = 'none';
    }
}

function renderBiasResults(data) {
    const om = data.overall_metrics;
    document.getElementById('overall-metrics').innerHTML = `
        <div class="metric-box"><div class="metric-value">${om.f1_score}</div><div class="metric-label">F1-Score</div></div>
        <div class="metric-box"><div class="metric-value">${om.recall}</div><div class="metric-label">Recall</div></div>
        <div class="metric-box"><div class="metric-value">${om.precision}</div><div class="metric-label">Precision</div></div>
        <div class="metric-box"><div class="metric-value">${om.total_samples}</div><div class="metric-label">Test Samples</div></div>
    `;

    renderAuditGroup('age-audit', data.age_group);
    renderAuditGroup('gender-audit', data.gender);
    renderAuditGroup('imd-audit', data.imd_band);
    generateBiasSummary(data);
    biasAuditData = data;
}

function renderAuditGroup(containerId, audit) {
    const container = document.getElementById(containerId);
    const dpClass = audit.dp_status === 'Pass' ? 'pass' : 'fail';
    const eoClass = audit.eo_status === 'Pass' ? 'pass' : 'fail';

    let html = `
        <div class="bias-bars">
            <div class="bias-section-title">Demographic Parity Difference</div>
    `;

    for (const [group, metrics] of Object.entries(audit.groups)) {
        const dpVal = metrics.positive_prediction_rate;
        const barWidth = Math.min(dpVal * 500, 100);
        const status = dpVal <= 0.10 ? 'PASS' : (dpVal <= 0.12 ? 'WARN' : 'FAIL');
        const statusClass = status.toLowerCase();
        html += `
            <div class="bias-bar-row">
                <span class="bias-bar-label">${group}</span>
                <div class="bias-bar-track">
                    <div class="bias-bar-fill ${statusClass}" style="width:${barWidth}%"></div>
                    <span class="bias-bar-value">${dpVal.toFixed(2)}</span>
                </div>
                <span class="bias-status-tag ${statusClass}">[${status}]</span>
            </div>
        `;
    }

    html += `</div>
        <div class="audit-summary" style="margin-top:16px;">
            <div class="audit-metric ${dpClass}">
                <span class="status-badge ${dpClass}">${audit.dp_status}</span>
                Demographic Parity: ${audit.demographic_parity_diff}
            </div>
            <div class="audit-metric ${eoClass}">
                <span class="status-badge ${eoClass}">${audit.eo_status}</span>
                Equalised Odds: ${audit.equalised_odds_diff}
            </div>
        </div>
    `;

    container.innerHTML = html;
}

function generateBiasSummary(data) {
    const card = document.getElementById('bias-summary-card');
    const text = document.getElementById('bias-summary-text');

    let failures = [];
    if (data.age_group.dp_status === 'Fail') failures.push('age (demographic parity)');
    if (data.age_group.eo_status === 'Fail') failures.push('age (equalised odds)');
    if (data.gender.dp_status === 'Fail') failures.push('gender (demographic parity)');
    if (data.gender.eo_status === 'Fail') failures.push('gender (equalised odds)');
    if (data.imd_band.dp_status === 'Fail') failures.push('IMD (demographic parity)');
    if (data.imd_band.eo_status === 'Fail') failures.push('IMD (equalised odds)');

    if (failures.length === 0) {
        text.textContent = 'Model shows acceptable fairness across all protected attribute groups. All metrics within the 0.10 threshold.';
    } else {
        text.textContent = `Model shows acceptable fairness across most groups. The following exceed the 0.10 threshold: ${failures.join(', ')}. This may reflect genuine clinical risk rather than algorithmic bias.`;
    }
    card.style.display = 'block';
}

// ── Dark Mode ──

function toggleDarkMode() {
    document.body.classList.toggle('dark-mode');
    const isDark = document.body.classList.contains('dark-mode');
    localStorage.setItem('careattend-dark-mode', isDark ? '1' : '0');
}

if (localStorage.getItem('careattend-dark-mode') === '1') {
    document.body.classList.add('dark-mode');
}

// ── Risk History (FR-09, US-012) ──

function renderRiskHistory() {
    const card = document.getElementById('risk-history-card');
    card.style.display = 'block';
    const canvas = document.getElementById('risk-history-chart');
    if (riskHistoryChart) riskHistoryChart.destroy();

    riskHistoryChart = new Chart(canvas, {
        type: 'line',
        data: {
            labels: riskHistory.map((h, i) => `#${i + 1} (${h.time})`),
            datasets: [{
                label: 'DNA Risk %',
                data: riskHistory.map(h => h.percentage),
                borderColor: '#003087',
                backgroundColor: 'rgba(0,48,135,0.1)',
                borderWidth: 2,
                fill: true,
                tension: 0.3,
                pointBackgroundColor: riskHistory.map(h => {
                    const t = h.tier.toLowerCase();
                    return t === 'high' ? '#DA291C' : t === 'medium' ? '#FFB81C' : '#007F3B';
                }),
                pointRadius: 6,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: { min: 0, max: 100, title: { display: true, text: 'Risk %' } },
                x: { ticks: { font: { size: 11 } } },
            },
            plugins: { legend: { display: false } },
        }
    });
}

// ── Batch Upload (FR-08, US-010) ──

let batchFile = null;

function handleBatchFile(input) {
    if (input.files.length === 0) return;
    batchFile = input.files[0];
    document.getElementById('batch-file-info').style.display = 'flex';
    document.getElementById('batch-file-name').textContent = batchFile.name;
    document.getElementById('batch-submit-btn').style.display = 'block';
}

function clearBatchFile() {
    batchFile = null;
    document.getElementById('batch-file-input').value = '';
    document.getElementById('batch-file-info').style.display = 'none';
    document.getElementById('batch-submit-btn').style.display = 'none';
    document.getElementById('batch-results').style.display = 'none';
}

async function submitBatch() {
    if (!batchFile) return;
    const btn = document.getElementById('batch-submit-btn');
    btn.disabled = true;
    btn.querySelector('.btn-text').style.display = 'none';
    btn.querySelector('.btn-loading').style.display = 'inline';

    const formData = new FormData();
    formData.append('file', batchFile);

    try {
        const res = await fetch('/api/batch', {
            method: 'POST',
            headers: authToken ? { 'Authorization': `Bearer ${authToken}` } : {},
            body: formData,
        });

        if (res.status === 401) {
            alert('Session expired. Please log in again.');
            handleLogout();
            return;
        }

        if (!res.ok) {
            const err = await res.json();
            alert(err.error || 'Batch processing failed');
            return;
        }

        const csvText = await res.text();
        renderBatchResults(csvText);
        document.getElementById('batch-results').style.display = 'block';

        const blob = new Blob([csvText], { type: 'text/csv' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'batch_results.csv';
        a.click();
        URL.revokeObjectURL(url);
    } catch {
        alert('Batch upload failed. Check server connection.');
    } finally {
        btn.disabled = false;
        btn.querySelector('.btn-text').style.display = 'inline';
        btn.querySelector('.btn-loading').style.display = 'none';
    }
}

function renderBatchResults(csvText) {
    const lines = csvText.trim().split('\n');
    if (lines.length < 2) return;
    const headers = lines[0].split(',');
    const rows = lines.slice(1).map(l => l.split(','));

    let highCount = 0, medCount = 0, lowCount = 0;
    rows.forEach(r => {
        const tierIdx = headers.indexOf('risk_tier');
        if (tierIdx >= 0) {
            const t = r[tierIdx];
            if (t === 'High') highCount++;
            else if (t === 'Medium') medCount++;
            else lowCount++;
        }
    });

    document.getElementById('batch-summary').innerHTML = `
        <div class="metric-box"><div class="metric-value">${rows.length}</div><div class="metric-label">Total Patients</div></div>
        <div class="metric-box" style="border-top:3px solid #DA291C"><div class="metric-value">${highCount}</div><div class="metric-label">High Risk</div></div>
        <div class="metric-box" style="border-top:3px solid #FFB81C"><div class="metric-value">${medCount}</div><div class="metric-label">Medium Risk</div></div>
        <div class="metric-box" style="border-top:3px solid #007F3B"><div class="metric-value">${lowCount}</div><div class="metric-label">Low Risk</div></div>
    `;

    let tableHtml = '<table class="audit-table"><thead><tr>';
    headers.forEach(h => tableHtml += `<th>${h}</th>`);
    tableHtml += '</tr></thead><tbody>';
    rows.forEach(r => {
        tableHtml += '<tr>';
        r.forEach((cell, i) => {
            let cls = '';
            if (headers[i] === 'risk_tier') {
                cls = cell === 'High' ? 'style="color:#DA291C;font-weight:700"' :
                      cell === 'Medium' ? 'style="color:#B8860B;font-weight:700"' :
                      'style="color:#007F3B;font-weight:700"';
            }
            tableHtml += `<td ${cls}>${cell}</td>`;
        });
        tableHtml += '</tr>';
    });
    tableHtml += '</tbody></table>';
    document.getElementById('batch-table-container').innerHTML = tableHtml;
}

// ── PDF Export (US-011) ──

function exportBiasPDF() {
    if (!biasAuditData) {
        alert('Run bias audit first before exporting.');
        return;
    }
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    const data = biasAuditData;
    let y = 20;

    doc.setFontSize(18);
    doc.setTextColor(0, 48, 135);
    doc.text('Care Attend - Ethical Bias Audit Report', 14, y);
    y += 10;

    doc.setFontSize(10);
    doc.setTextColor(66, 85, 99);
    doc.text(`Generated: ${new Date().toLocaleString()}`, 14, y);
    y += 10;

    // Overall metrics
    doc.setFontSize(14);
    doc.setTextColor(0, 48, 135);
    doc.text('Overall Model Performance', 14, y);
    y += 8;

    const om = data.overall_metrics;
    doc.autoTable({
        startY: y,
        head: [['Metric', 'Value']],
        body: [
            ['F1-Score', om.f1_score.toString()],
            ['Recall', om.recall.toString()],
            ['Precision', om.precision.toString()],
            ['Test Samples', om.total_samples.toString()],
        ],
        theme: 'grid',
        headStyles: { fillColor: [0, 48, 135] },
        margin: { left: 14 },
    });
    y = doc.lastAutoTable.finalY + 10;

    // Group audits
    const groups = [
        { name: 'Age Group', data: data.age_group },
        { name: 'Gender', data: data.gender },
        { name: 'IMD Band', data: data.imd_band },
    ];

    groups.forEach(g => {
        if (y > 240) { doc.addPage(); y = 20; }
        doc.setFontSize(14);
        doc.setTextColor(0, 48, 135);
        doc.text(`${g.name} Fairness`, 14, y);
        y += 8;

        const rows = Object.entries(g.data.groups).map(([name, m]) => [
            name,
            m.count.toString(),
            (m.positive_prediction_rate * 100).toFixed(1) + '%',
            (m.true_positive_rate * 100).toFixed(1) + '%',
            (m.false_positive_rate * 100).toFixed(1) + '%',
        ]);

        doc.autoTable({
            startY: y,
            head: [['Group', 'Count', 'PPR', 'TPR', 'FPR']],
            body: rows,
            theme: 'grid',
            headStyles: { fillColor: [0, 48, 135] },
            margin: { left: 14 },
        });
        y = doc.lastAutoTable.finalY + 5;

        doc.setFontSize(10);
        const dpColor = g.data.dp_status === 'Pass' ? [0, 127, 59] : [218, 41, 28];
        const eoColor = g.data.eo_status === 'Pass' ? [0, 127, 59] : [218, 41, 28];
        doc.setTextColor(...dpColor);
        doc.text(`Demographic Parity: ${g.data.demographic_parity_diff} [${g.data.dp_status}]`, 14, y);
        y += 5;
        doc.setTextColor(...eoColor);
        doc.text(`Equalised Odds: ${g.data.equalised_odds_diff} [${g.data.eo_status}]`, 14, y);
        y += 10;
    });

    // Summary
    if (y > 250) { doc.addPage(); y = 20; }
    doc.setFontSize(12);
    doc.setTextColor(0, 48, 135);
    doc.text('Plain-English Summary', 14, y);
    y += 6;
    doc.setFontSize(10);
    doc.setTextColor(66, 85, 99);
    const summaryText = document.getElementById('bias-summary-text').textContent;
    const splitText = doc.splitTextToSize(summaryText, 180);
    doc.text(splitText, 14, y);
    y += splitText.length * 5 + 10;

    doc.setFontSize(8);
    doc.setTextColor(150);
    doc.text('Care Attend | COM668 Computing Project | Ulster University | GDPR Art 5(1)(c) Compliant', 14, 285);

    doc.save('CareAttend_Bias_Audit_Report.pdf');
}

// ── Prediction Feedback (Feature 12) ──

async function submitFeedback(outcome) {
    if (!lastResult || !lastResult.sessionId) return;
    try {
        const res = await fetch('/api/feedback', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ prediction_id: lastResult.sessionId, outcome }),
        });
        const data = await res.json();
        const el = document.getElementById('feedback-response');
        el.innerHTML = `<div class="auth-success">Feedback recorded: ${outcome}. Thank you.</div>`;
        el.style.display = 'block';
        document.getElementById('feedback-card').querySelectorAll('button').forEach(b => b.disabled = true);
    } catch {
        alert('Failed to submit feedback.');
    }
}

// ── Practice Dashboard (Feature 11) ──

async function loadDashboard() {
    try {
        const res = await fetch('/api/dashboard', { headers: authHeaders() });
        if (res.status === 401) { handleLogout(); return; }
        const data = await res.json();
        renderDashboard(data);
        document.getElementById('dashboard-content').style.display = 'block';
    } catch {
        alert('Dashboard load failed.');
    }
}

function renderDashboard(data) {
    if (data.total === 0) {
        document.getElementById('dashboard-metrics').innerHTML =
            '<p style="text-align:center;color:#AEB7BD;padding:20px;">No assessments yet. Complete patient assessments to populate dashboard.</p>';
        return;
    }

    document.getElementById('dashboard-metrics').innerHTML = `
        <div class="metric-box"><div class="metric-value">${data.total}</div><div class="metric-label">Total Assessed</div></div>
        <div class="metric-box" style="border-top:3px solid #DA291C"><div class="metric-value">${data.high_risk}</div><div class="metric-label">High Risk</div></div>
        <div class="metric-box" style="border-top:3px solid #FFB81C"><div class="metric-value">${data.medium_risk}</div><div class="metric-label">Medium Risk</div></div>
        <div class="metric-box" style="border-top:3px solid #007F3B"><div class="metric-value">${data.low_risk}</div><div class="metric-label">Low Risk</div></div>
        <div class="metric-box"><div class="metric-value">${(data.average_risk * 100).toFixed(1)}%</div><div class="metric-label">Avg Risk</div></div>
        <div class="metric-box"><div class="metric-value">${data.feedback_given}</div><div class="metric-label">Feedback Given</div></div>
    `;

    // Age breakdown
    let ageHtml = '<table class="audit-table"><thead><tr><th>Age Group</th><th>Total</th><th>High Risk</th><th>% High</th></tr></thead><tbody>';
    for (const [group, stats] of Object.entries(data.age_breakdown || {})) {
        const pct = stats.total > 0 ? ((stats.high_risk / stats.total) * 100).toFixed(1) : '0.0';
        ageHtml += `<tr><td><strong>${group}</strong></td><td>${stats.total}</td><td>${stats.high_risk}</td><td>${pct}%</td></tr>`;
    }
    ageHtml += '</tbody></table>';
    document.getElementById('dashboard-age-breakdown').innerHTML = ageHtml;

    // Recent assessments
    let recentHtml = '<table class="audit-table"><thead><tr><th>ID</th><th>Age</th><th>Group</th><th>Risk</th><th>Score</th></tr></thead><tbody>';
    (data.recent_assessments || []).forEach(r => {
        const cls = r.risk_tier === 'High' ? 'color:#DA291C;font-weight:700' :
                    r.risk_tier === 'Medium' ? 'color:#B8860B;font-weight:700' : 'color:#007F3B;font-weight:700';
        recentHtml += `<tr><td>${r.id}</td><td>${r.age}</td><td>${r.age_group}</td><td style="${cls}">${r.risk_tier}</td><td>${(r.probability * 100).toFixed(1)}%</td></tr>`;
    });
    recentHtml += '</tbody></table>';
    document.getElementById('dashboard-recent').innerHTML = recentHtml;

    // Feedback summary
    document.getElementById('dashboard-feedback').innerHTML = data.feedback_given > 0
        ? `<p>${data.feedback_given} feedback responses received out of ${data.total} predictions.</p>`
        : '<p style="color:#AEB7BD;">No feedback submitted yet.</p>';
}

// ── EHR Lookup (Feature 10 - Mock) ──

async function lookupEHR() {
    const nhsNum = document.getElementById('ehr-nhs-number').value.trim();
    if (!nhsNum) { alert('Enter an NHS number (e.g. NHS001)'); return; }

    try {
        const res = await fetch(`/api/ehr/lookup/${nhsNum}`, { headers: authHeaders() });
        const data = await res.json();
        if (!res.ok) { alert(data.error || 'Patient not found'); return; }

        const p = data.patient;
        document.getElementById('age').value = p.Age || '';
        document.getElementById('gender').value = p.Gender !== undefined ? p.Gender.toString() : '';
        document.getElementById('imd').value = p.IMDDecile || '';
        document.getElementById('priordna').value = p.PriorDNACount || '';
        document.getElementById('hypertension').checked = !!p.Hypertension;
        document.getElementById('diabetes').checked = !!p.Diabetes;
        document.getElementById('disability').checked = !!p.Disability;

        document.getElementById('age').dispatchEvent(new Event('input'));
        alert(`Auto-filled from mock EHR: ${p.name} (${nhsNum})`);
    } catch {
        alert('EHR lookup failed. Check server connection.');
    }
}

// ── Ethics Framework (Feature 19) ──

async function loadEthicsFramework() {
    try {
        const res = await fetch('/api/ethics-framework', { headers: authHeaders() });
        if (res.status === 401) { handleLogout(); return; }
        const data = await res.json();
        renderEthicsFramework(data);
    } catch { alert('Failed to load ethics framework.'); }
}

function renderEthicsFramework(data) {
    const container = document.getElementById('ethics-content');
    let html = `<div class="card"><h3 class="card-title">${data.framework}</h3></div>`;

    data.principles.forEach(p => {
        const statusColor = p.status === 'Addressed' ? '#007F3B' : '#FFB81C';
        const statusBg = p.status === 'Addressed' ? '#E8F5E9' : '#FFF8E1';
        html += `
            <div class="card">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
                    <h4 style="color:var(--nhs-blue);font-size:15px;">${p.id}: ${p.principle}</h4>
                    <span style="background:${statusBg};color:${statusColor};padding:4px 14px;border-radius:12px;font-size:12px;font-weight:700;">${p.status}</span>
                </div>
                <ul style="margin:0;padding-left:20px;font-size:13px;color:var(--nhs-dark-grey);line-height:1.8;">
                    ${p.evidence.map(e => `<li>${e}</li>`).join('')}
                </ul>
            </div>
        `;
    });

    container.innerHTML = html;
    container.style.display = 'block';
}

async function runCrossValidation() {
    const btn = event.target;
    btn.disabled = true;
    btn.textContent = 'Running (may take 30s)...';

    try {
        const res = await fetch('/api/evaluation/cross-validation', {
            method: 'POST', headers: authHeaders(),
        });
        if (res.status === 401) { handleLogout(); return; }
        const data = await res.json();
        renderCVResults(data);
    } catch { alert('Cross-validation failed.'); }
    finally { btn.disabled = false; btn.textContent = 'Run Cross-Validation'; }
}

function renderCVResults(data) {
    let html = '<table class="audit-table"><thead><tr>';
    html += '<th>Model</th><th>Mean F1</th><th>95% CI</th><th>Mean Recall</th><th>95% CI</th><th>Mean ROC-AUC</th></tr></thead><tbody>';

    for (const [name, m] of Object.entries(data.models)) {
        html += `<tr>
            <td><strong>${name}</strong></td>
            <td>${m.mean_f1.toFixed(4)} &plusmn; ${m.std_f1.toFixed(4)}</td>
            <td>[${m.ci_95_f1.lower}, ${m.ci_95_f1.upper}]</td>
            <td>${m.mean_recall.toFixed(4)} &plusmn; ${m.std_recall.toFixed(4)}</td>
            <td>[${m.ci_95_recall.lower}, ${m.ci_95_recall.upper}]</td>
            <td>${m.mean_roc_auc.toFixed(4)}</td>
        </tr>`;
    }
    html += '</tbody></table>';
    document.getElementById('cv-table-container').innerHTML = html;

    // Significance tests
    if (data.significance_tests && data.significance_tests.length > 0) {
        let sigHtml = '<table class="audit-table"><thead><tr><th>Model A</th><th>Model B</th><th>p-value</th><th>Significant (p<0.05)</th></tr></thead><tbody>';
        data.significance_tests.forEach(t => {
            const sigClass = t.significant_at_005 ? 'color:#DA291C;font-weight:700' : 'color:#007F3B';
            sigHtml += `<tr><td>${t.model_a}</td><td>${t.model_b}</td><td>${t.mcnemar_p_value.toFixed(6)}</td>
                <td style="${sigClass}">${t.significant_at_005 ? 'Yes' : 'No'}</td></tr>`;
        });
        sigHtml += '</tbody></table>';
        document.getElementById('cv-sig-content').innerHTML = sigHtml;
        document.getElementById('cv-significance').style.display = 'block';
    }

    // DL narrative
    if (data.dl_comparison) {
        document.getElementById('dl-narrative-text').textContent = data.dl_comparison;
        document.getElementById('dl-narrative').style.display = 'block';
    }

    document.getElementById('cv-results').style.display = 'block';
}

// Drag & drop for batch upload
const dropArea = document.getElementById('batch-upload-area');
if (dropArea) {
    ['dragenter', 'dragover'].forEach(e => {
        dropArea.addEventListener(e, (ev) => { ev.preventDefault(); dropArea.classList.add('drag-over'); });
    });
    ['dragleave', 'drop'].forEach(e => {
        dropArea.addEventListener(e, (ev) => { ev.preventDefault(); dropArea.classList.remove('drag-over'); });
    });
    dropArea.addEventListener('drop', (ev) => {
        const files = ev.dataTransfer.files;
        if (files.length > 0 && files[0].name.endsWith('.csv')) {
            document.getElementById('batch-file-input').files = files;
            handleBatchFile(document.getElementById('batch-file-input'));
        }
    });
}


// ── Carer / Family Proxy Mode (Digital Inclusion Bridge) ──

let activeProxy = null;

async function registerCarerProxy() {
    const carerName = document.getElementById('proxy-carer-name').value.trim();
    const relationship = document.getElementById('proxy-relationship').value;
    const patientId = document.getElementById('proxy-patient-id').value.trim();
    const carerContact = document.getElementById('proxy-carer-contact').value.trim();
    const reason = document.getElementById('proxy-reason').value.trim();

    if (!carerName || !relationship || !patientId) {
        alert('Carer name, relationship, and patient identifier required.');
        return;
    }

    try {
        const res = await fetch('/api/carer-proxy', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ carerName, relationship, patientIdentifier: patientId, carerContact, reason }),
        });
        const data = await res.json();
        if (res.ok) {
            activeProxy = data.proxy;
            alert('Proxy registered for ' + carerName + '. You can now assess on behalf of the patient.');
            document.getElementById('proxy-register-form').style.display = 'none';
            document.getElementById('proxy-active-badge').style.display = 'flex';
            document.getElementById('proxy-active-name').textContent = carerName + ' (' + relationship + ')';
        } else {
            alert(data.error || 'Failed to register proxy.');
        }
    } catch {
        alert('Connection error.');
    }
}

function clearCarerProxy() {
    activeProxy = null;
    document.getElementById('proxy-register-form').style.display = 'block';
    document.getElementById('proxy-active-badge').style.display = 'none';
    document.getElementById('proxy-carer-name').value = '';
    document.getElementById('proxy-patient-id').value = '';
    document.getElementById('proxy-carer-contact').value = '';
    document.getElementById('proxy-reason').value = '';
}

function toggleProxyPanel() {
    const panel = document.getElementById('proxy-panel');
    panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
}


// ── Slot Optimisation ──

async function runSlotOptimisation() {
    const textarea = document.getElementById('slot-input-data');
    let appointments;
    try {
        appointments = JSON.parse(textarea.value);
        if (!Array.isArray(appointments)) appointments = [appointments];
    } catch {
        alert('Invalid JSON. Enter array of patient objects.');
        return;
    }

    try {
        const res = await fetch('/api/slot-optimisation', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ appointments }),
        });
        const data = await res.json();
        if (res.ok) {
            renderSlotResults(data);
        } else {
            alert(data.error || 'Slot optimisation failed.');
        }
    } catch {
        alert('Connection error.');
    }
}

function renderSlotResults(data) {
    const container = document.getElementById('slot-results');
    container.style.display = 'block';
    const summary = data.summary;
    document.getElementById('slot-summary').innerHTML = `
        <div class="metric-box"><div class="metric-value">${summary.total_slots}</div><div class="metric-label">Total Slots</div></div>
        <div class="metric-box"><div class="metric-value">${summary.overbookable}</div><div class="metric-label">Overbookable</div></div>
        <div class="metric-box"><div class="metric-value">${summary.total_expected_waste_minutes} min</div><div class="metric-label">Expected Waste</div></div>
        <div class="metric-box"><div class="metric-value">${summary.potential_recovery_percent}%</div><div class="metric-label">Recovery Potential</div></div>
    `;
    let tableHTML = '<table class="audit-table"><thead><tr><th>Slot</th><th>DNA Risk</th><th>Tier</th><th>Overbook?</th><th>Waste (min)</th><th>Recommendation</th></tr></thead><tbody>';
    data.slots.forEach(s => {
        if (s.error) {
            tableHTML += '<tr><td>' + s.slot + '</td><td colspan="5" style="color:#DA291C;">' + s.error + '</td></tr>';
        } else {
            const overbookIcon = s.can_overbook ? '<span style="color:#007F3B;">&#10003;</span>' : '&mdash;';
            const tierCls = s.risk_tier === 'High' ? 'color:#DA291C;font-weight:700' :
                            s.risk_tier === 'Medium' ? 'color:#B8860B;font-weight:700' : 'color:#007F3B;font-weight:700';
            tableHTML += '<tr><td>' + s.slot + '</td><td>' + (s.dna_probability * 100).toFixed(1) + '%</td><td style="' + tierCls + '">' + s.risk_tier + '</td><td>' + overbookIcon + '</td><td>' + s.expected_waste_minutes + '</td><td style="font-size:13px;">' + s.recommendation + '</td></tr>';
        }
    });
    tableHTML += '</tbody></table>';
    document.getElementById('slot-table-container').innerHTML = tableHTML;
}


// ── Patient Nudge Generator ──

async function generateNudge() {
    const patientName = document.getElementById('nudge-patient-name').value.trim();
    const language = document.getElementById('nudge-language').value;

    const age = parseInt(document.getElementById('age').value) || 0;
    const gender = parseInt(document.getElementById('gender').value) || 0;
    const leadTime = parseInt(document.getElementById('leadtime').value) || 0;
    const sms = document.getElementById('sms-check').checked ? 1 : 0;
    const priorDNA = parseInt(document.getElementById('priordna').value) || 0;
    const imd = parseInt(document.getElementById('imd').value) || 5;

    if (!age && !priorDNA && !imd) {
        alert('Fill in the Assessment form first, then generate a nudge.');
        return;
    }

    const patient = {
        Age: age, Gender: gender, AppointmentLeadTimeDays: leadTime,
        SMSReceived: sms, PriorDNACount: priorDNA, IMDDecile: imd || 5,
        Hypertension: document.getElementById('hypertension').checked ? 1 : 0,
        Diabetes: document.getElementById('diabetes').checked ? 1 : 0,
        Alcoholism: document.getElementById('alcoholism').checked ? 1 : 0,
        Disability: document.getElementById('disability').checked ? 1 : 0,
    };

    try {
        const res = await fetch('/api/patient-nudge', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ patient, patientName, language }),
        });
        const data = await res.json();
        if (res.ok) {
            document.getElementById('nudge-result').style.display = 'block';
            document.getElementById('nudge-message-text').textContent = data.message;
            document.getElementById('nudge-type-badge').textContent = data.nudge_type;
            document.getElementById('nudge-risk-info').textContent = 'Risk: ' + data.risk_probability + ' (' + data.risk_tier + ')';
            document.getElementById('nudge-factors').innerHTML = data.personalisation_factors.map(function(f) {
                return '<span class="nudge-factor-tag">' + f.replace(/_/g, ' ') + '</span>';
            }).join(' ');
        } else {
            alert(data.error || 'Nudge generation failed.');
        }
    } catch {
        alert('Connection error.');
    }
}

function copyNudgeMessage() {
    const text = document.getElementById('nudge-message-text').textContent;
    navigator.clipboard.writeText(text).then(function() {
        alert('Message copied to clipboard.');
    });
}


// ── Keyboard Shortcuts ──

document.addEventListener('keydown', function(e) {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') return;
    if (!authToken) return;

    const tabs = ['assessment', 'results', 'dashboard', 'batch', 'bias', 'ethics', 'slots', 'nudge'];
    const key = e.key;

    if (key >= '1' && key <= '8') {
        e.preventDefault();
        switchTab(tabs[parseInt(key) - 1]);
    } else if (key.toLowerCase() === 'n') {
        e.preventDefault();
        switchTab('assessment');
        document.getElementById('age').focus();
    } else if (key.toLowerCase() === 'd') {
        e.preventDefault();
        toggleDarkMode();
    }
});


// ── 2FA Functions ──

async function start2FASetup() {
    try {
        const res = await fetch('/api/profile/2fa/setup', {
            method: 'POST',
            headers: authHeaders(),
        });
        const data = await res.json();
        if (res.ok) {
            document.getElementById('2fa-setup-area').style.display = 'none';
            document.getElementById('2fa-qr-area').style.display = 'block';
            document.getElementById('2fa-secret-key').textContent = data.secret;
        } else {
            alert(data.error || '2FA setup failed.');
        }
    } catch {
        alert('Failed to start 2FA setup.');
    }
}

async function verify2FA() {
    const code = document.getElementById('2fa-verify-code').value.trim();
    if (code.length !== 6) {
        alert('Enter 6-digit code from authenticator app.');
        return;
    }
    try {
        const res = await fetch('/api/profile/2fa/enable', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ code }),
        });
        const data = await res.json();
        if (res.ok) {
            alert('2FA enabled! Your account is now more secure.');
            document.getElementById('2fa-qr-area').style.display = 'none';
            document.getElementById('2fa-disable-area').style.display = 'block';
            const badge = document.getElementById('2fa-badge');
            badge.className = 'ac-2fa-badge enabled';
            badge.innerHTML = '&#128274; Enabled';
        } else {
            alert(data.error || 'Verification failed.');
        }
    } catch {
        alert('Verification failed.');
    }
}

async function disable2FA() {
    const pw = document.getElementById('2fa-disable-pw').value;
    if (!pw) { alert('Enter password.'); return; }
    try {
        const res = await fetch('/api/profile/2fa/disable', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ password: pw }),
        });
        const data = await res.json();
        if (res.ok) {
            alert('2FA disabled.');
            document.getElementById('2fa-disable-area').style.display = 'none';
            document.getElementById('2fa-setup-area').style.display = 'block';
            document.getElementById('2fa-disable-pw').value = '';
            const badge = document.getElementById('2fa-badge');
            badge.className = 'ac-2fa-badge disabled';
            badge.innerHTML = '&#128274; Disabled';
        } else {
            alert(data.error || 'Failed to disable 2FA.');
        }
    } catch {
        alert('Failed to disable 2FA.');
    }
}


// ── Guided Tour ──

const TOUR_STEPS = [
    { title: 'Welcome to Care Attend', description: 'This NHS tool uses AI to predict which patients are at risk of missing their appointments (DNAs). It explains predictions using SHAP and monitors for demographic bias. This quick tour spotlights each feature in turn.', tab: null, selector: null },
    { title: '1. Patient Assessment', description: 'Enter patient details here — age, gender, appointment lead time, prior DNA count, clinical flags, and IMD deprivation decile. You can also use the EHR auto-fill or Carer Proxy mode for digitally excluded patients.', tab: 'assessment', selector: '[data-tab="assessment"]' },
    { title: '2. Risk Results', description: 'After assessment, view the DNA risk gauge, SHAP explainability chart showing WHY the score was given, and recommended interventions tailored to the patient\'s profile.', tab: 'results', selector: '[data-tab="results"]' },
    { title: '3. Practice Dashboard', description: 'See practice-wide DNA risk overview — total assessments, risk breakdown by age group, recent assessments, and feedback accuracy. All session-scoped.', tab: 'dashboard', selector: '[data-tab="dashboard"]' },
    { title: '4. Batch Upload', description: 'Upload a CSV of up to 100 patients for bulk risk assessment. Download results as CSV with risk scores, tiers, and top risk factors.', tab: 'batch', selector: '[data-tab="batch"]' },
    { title: '5. Bias Monitor', description: 'Run fairness audits across age, gender, and IMD groups. Checks demographic parity and equalised odds with 0.10 threshold per NHS AI ethics guidance. Export PDF reports.', tab: 'bias', selector: '[data-tab="bias"]' },
    { title: '6. Slot Optimisation', description: 'Analyse appointment slots to find overbooking opportunities. Slots with 40%+ DNA risk can be double-booked to recover wasted clinical time.', tab: 'slots', selector: '[data-tab="slots"]' },
    { title: '7. Patient Nudge', description: 'Generate personalised, non-stigmatising messages for at-risk patients in English, Welsh, Urdu, or Polish. Messages are tailored to patient circumstances.', tab: 'nudge', selector: '[data-tab="nudge"]' },
];

let currentTourStep = 0;

function startGuidedTour() {
    currentTourStep = 0;
    document.getElementById('tour-overlay').style.display = 'flex';
    renderTourStep();
}

function clearTourHighlight() {
    document.querySelectorAll('.tour-highlight').forEach(el =>
        el.classList.remove('tour-highlight', 'tour-highlight-pulse'));
}

function renderTourStep() {
    const step = TOUR_STEPS[currentTourStep];
    document.getElementById('tour-title').textContent = step.title;
    document.getElementById('tour-description').textContent = step.description;
    document.getElementById('tour-step-label').textContent = 'Step ' + (currentTourStep + 1) + ' of ' + TOUR_STEPS.length;
    document.getElementById('tour-progress-fill').style.width = ((currentTourStep + 1) / TOUR_STEPS.length * 100) + '%';
    document.getElementById('tour-prev-btn').style.display = currentTourStep === 0 ? 'none' : 'inline-block';
    document.getElementById('tour-next-btn').textContent = currentTourStep === TOUR_STEPS.length - 1 ? 'Finish' : 'Next →';

    if (step.tab) switchTab(step.tab);

    // Reset previous spotlight + card positioning.
    clearTourHighlight();
    const overlay = document.getElementById('tour-overlay');
    const card = document.getElementById('tour-card');
    card.classList.remove('positioned', 'pos-bottom', 'pos-top');
    card.style.left = '';
    card.style.top = '';

    const target = step.selector ? document.querySelector(step.selector) : null;
    if (target) {
        // Anchored mode: spotlight the element, position the card beside it.
        overlay.classList.add('anchored');
        target.classList.add('tour-highlight', 'tour-highlight-pulse');
        target.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' });
        positionTourCard(card, target);
    } else {
        // Centred modal for intro/finish steps.
        overlay.classList.remove('anchored');
    }
}

function positionTourCard(card, target) {
    // Position after layout settles so offsetWidth/Height are correct.
    requestAnimationFrame(() => {
        const r = target.getBoundingClientRect();
        card.classList.add('positioned');
        const cw = card.offsetWidth;
        const ch = card.offsetHeight;
        const margin = 12;

        let left = r.left + r.width / 2 - cw / 2;
        left = Math.max(margin, Math.min(left, window.innerWidth - cw - margin));

        let top = r.bottom + margin;
        let pos = 'pos-bottom';
        if (top + ch > window.innerHeight - margin) {
            top = r.top - ch - margin;
            pos = 'pos-top';
        }
        top = Math.max(margin, top);

        card.classList.add(pos);
        card.style.left = left + 'px';
        card.style.top = top + 'px';
    });
}

function tourNext() {
    if (currentTourStep < TOUR_STEPS.length - 1) {
        currentTourStep++;
        renderTourStep();
    } else {
        endTour();
    }
}

function tourPrev() {
    if (currentTourStep > 0) {
        currentTourStep--;
        renderTourStep();
    }
}

function endTour() {
    clearTourHighlight();
    const overlay = document.getElementById('tour-overlay');
    const card = document.getElementById('tour-card');
    overlay.classList.remove('anchored');
    overlay.style.display = 'none';
    card.classList.remove('positioned', 'pos-bottom', 'pos-top');
    card.style.left = '';
    card.style.top = '';
    switchTab('assessment');
}


// ── Session Timer ──

let countdownInterval = null;

function startSessionCountdown() {
    let elapsed = 0;
    const el = document.getElementById('session-countdown');
    if (!el) return;
    clearInterval(countdownInterval);
    countdownInterval = setInterval(function() {
        elapsed++;
        const h = Math.floor(elapsed / 3600);
        const m = Math.floor((elapsed % 3600) / 60);
        const s = elapsed % 60;
        if (h > 0) {
            el.textContent = h + ':' + (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
        } else {
            el.textContent = m + ':' + (s < 10 ? '0' : '') + s;
        }
    }, 1000);
}

const _origShowMainApp = showMainApp;
showMainApp = function(username) {
    _origShowMainApp(username);
    startSessionCountdown();
    if (typeof lucide !== 'undefined') lucide.createIcons();
};


// ── Notifications ──

let notifications = [];

function toggleNotifications() {
    const dd = document.getElementById('notification-dropdown');
    dd.style.display = dd.style.display === 'none' ? 'block' : 'none';
}

function addNotification(title, desc, type) {
    notifications.unshift({ title, desc, type, time: new Date() });
    if (notifications.length > 20) notifications.pop();
    renderNotifications();
    updateNotifBadge();
}

function renderNotifications() {
    const list = document.getElementById('notif-list');
    if (!notifications.length) {
        list.innerHTML = '<div class="notif-empty">No notifications yet</div>';
        return;
    }
    list.innerHTML = notifications.map(function(n) {
        var iconColor = n.type === 'error' ? '#DA291C' : n.type === 'success' ? '#007F3B' : '#003087';
        return '<div class="notif-item"><div class="notif-icon" style="color:' + iconColor + ';">&#9679;</div><div class="notif-content"><strong>' + n.title + '</strong><p>' + n.desc + '</p><span class="notif-time">' + timeAgo(n.time) + '</span></div></div>';
    }).join('');
}

function updateNotifBadge() {
    var badge = document.getElementById('notif-badge');
    if (notifications.length > 0) {
        badge.textContent = notifications.length;
        badge.style.display = 'inline-block';
    } else {
        badge.style.display = 'none';
    }
}

function clearAllNotifications() {
    notifications = [];
    renderNotifications();
    updateNotifBadge();
}

function timeAgo(date) {
    var seconds = Math.floor((new Date() - date) / 1000);
    if (seconds < 60) return 'Just now';
    var minutes = Math.floor(seconds / 60);
    if (minutes < 60) return minutes + 'm ago';
    var hours = Math.floor(minutes / 60);
    if (hours < 24) return hours + 'h ago';
    return Math.floor(hours / 24) + 'd ago';
}


// ── AI Chatbot ──

let chatbotOpen = false;

function toggleChatbot() {
    chatbotOpen = !chatbotOpen;
    document.getElementById('chatbot-panel').style.display = chatbotOpen ? 'flex' : 'none';
    if (chatbotOpen && typeof lucide !== 'undefined') lucide.createIcons();
}

function sendSuggestion(text) {
    document.getElementById('chatbot-input').value = text;
    sendChatMessage();
    var suggestions = document.getElementById('chat-suggestions');
    if (suggestions) suggestions.style.display = 'none';
}

function sendChatMessage() {
    var input = document.getElementById('chatbot-input');
    var text = input.value.trim();
    if (!text) return;
    appendChatMessage(text, 'user');
    input.value = '';
    showTypingIndicator();
    setTimeout(function() {
        removeTypingIndicator();
        var response = getChatbotResponse(text);
        appendChatMessage(response, 'bot');
    }, 800);
}

function appendChatMessage(text, sender) {
    var container = document.getElementById('chatbot-messages');
    var div = document.createElement('div');
    div.className = 'chat-msg ' + sender;
    var avatar = sender === 'bot' ? '<div class="chat-avatar">AI</div>' : '<div class="chat-avatar">You</div>';
    div.innerHTML = avatar + '<div class="chat-bubble">' + text + '</div>';
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
}

function showTypingIndicator() {
    var container = document.getElementById('chatbot-messages');
    var div = document.createElement('div');
    div.className = 'chat-msg bot typing-indicator';
    div.id = 'typing-indicator';
    div.innerHTML = '<div class="chat-avatar">AI</div><div class="chat-bubble"><span class="typing-dots">...</span></div>';
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
}

function removeTypingIndicator() {
    var el = document.getElementById('typing-indicator');
    if (el) el.remove();
}

function getChatbotResponse(query) {
    var q = query.toLowerCase();
    if (q.includes('assess') || q.includes('predict') || q.includes('risk')) {
        return 'To assess a patient, go to the <strong>Assessment</strong> tab (press 1). Fill in demographics, appointment details, clinical flags, and IMD decile. Click "Assess Risk" to get a DNA prediction with SHAP explanations and recommended interventions.';
    } else if (q.includes('shap') || q.includes('explain')) {
        return '<strong>SHAP</strong> (SHapley Additive exPlanations) shows which factors contributed most to the prediction. Green bars reduce risk, red bars increase it. Each patient gets a personalised explanation — not a black box.';
    } else if (q.includes('bias') || q.includes('fair')) {
        return 'The <strong>Bias Monitor</strong> (tab 5) audits the model for fairness across age, gender, and IMD groups. It checks demographic parity and equalised odds with a 0.10 threshold per NHS AI ethics guidance. You can export PDF reports for governance.';
    } else if (q.includes('privacy') || q.includes('gdpr') || q.includes('data')) {
        return 'Care Attend is <strong>GDPR Article 5(1)(c) compliant</strong>. No patient data is stored — all predictions are session-scoped. Passwords are hashed with bcrypt. Sessions expire after 30 minutes. No third-party analytics.';
    } else if (q.includes('batch') || q.includes('csv') || q.includes('upload')) {
        return 'The <strong>Batch Upload</strong> tab (press 4) lets you upload a CSV of up to 100 patients. Required columns: Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile. Results download as CSV.';
    } else if (q.includes('slot') || q.includes('overbook')) {
        return 'The <strong>Slot Optimisation</strong> tab (press 7) analyses appointment slots for overbooking opportunities. Paste JSON patient data — slots with 40%+ DNA risk are flagged as overbookable.';
    } else if (q.includes('nudge') || q.includes('message') || q.includes('patient comms')) {
        return 'The <strong>Patient Nudge</strong> tab (press 8) generates personalised, non-stigmatising messages in English, Welsh, Urdu, or Polish based on the patient\'s risk profile.';
    } else if (q.includes('2fa') || q.includes('two-factor') || q.includes('authenticator')) {
        return 'Enable <strong>2FA</strong> in your Account Centre > Security tab. It uses TOTP — compatible with Google Authenticator, Authy, or any TOTP app. You\'ll need the 6-digit code to log in.';
    } else if (q.includes('proxy') || q.includes('carer') || q.includes('digital exclusion')) {
        return 'The <strong>Carer Proxy</strong> mode (Assessment tab) lets a family member or carer enter patient data on behalf of digitally excluded patients — bridging the gap for 3.8M UK adults who\'ve never used the internet.';
    } else if (q.includes('shortcut') || q.includes('keyboard')) {
        return 'Press <strong>?</strong> to see keyboard shortcuts. Keys 1-8 switch tabs. N = new assessment, D = dark mode, G = guided tour, Esc = close panels.';
    } else if (q.includes('tour') || q.includes('guide') || q.includes('help')) {
        return 'Press the <strong>?</strong> button in the header or press G to start the guided tour. It walks through all 8 features step by step.';
    } else {
        return 'I can help with: patient assessment, SHAP explanations, bias monitoring, batch upload, slot optimisation, patient nudge, 2FA security, carer proxy mode, and more. What would you like to know?';
    }
}


// ── Toast Notifications ──

function showToast(message, type, duration) {
    type = type || 'info';
    duration = duration || 4000;
    var container = document.getElementById('toast-container');
    if (!container) return;
    var toast = document.createElement('div');
    toast.className = 'toast toast-' + type;
    var iconMap = { success: '&#10003;', error: '&#10007;', warning: '&#9888;', info: '&#8505;' };
    toast.innerHTML = '<span class="toast-icon">' + (iconMap[type] || iconMap.info) + '</span><span class="toast-msg">' + message + '</span>';
    container.appendChild(toast);
    setTimeout(function() { toast.classList.add('toast-show'); }, 10);
    setTimeout(function() {
        toast.classList.remove('toast-show');
        setTimeout(function() { toast.remove(); }, 300);
    }, duration);
}


// ── Keyboard Shortcuts (enhanced) ──

function openShortcuts() {
    document.getElementById('shortcuts-overlay').style.display = 'flex';
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function closeShortcuts() {
    document.getElementById('shortcuts-overlay').style.display = 'none';
}

// Override existing keyboard handler
document.removeEventListener('keydown', arguments.callee);
document.addEventListener('keydown', function(e) {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') return;
    if (!authToken) return;

    var tabs = ['assessment', 'results', 'dashboard', 'batch', 'bias', 'ethics', 'slots', 'nudge'];
    var key = e.key;

    if (key >= '1' && key <= '8') {
        e.preventDefault();
        switchTab(tabs[parseInt(key) - 1]);
    } else if (key === '?') {
        e.preventDefault();
        openShortcuts();
    } else if (key.toLowerCase() === 'n') {
        e.preventDefault();
        switchTab('assessment');
        document.getElementById('age').focus();
    } else if (key.toLowerCase() === 'd') {
        e.preventDefault();
        toggleDarkMode();
    } else if (key.toLowerCase() === 'g') {
        e.preventDefault();
        startGuidedTour();
    } else if (key === 'Escape') {
        closeProfile();
        closeShortcuts();
        if (chatbotOpen) toggleChatbot();
        document.getElementById('notification-dropdown').style.display = 'none';
    }
});


// ── Patient PDF Export ──

function exportPatientPDF() {
    if (!lastResult) { showToast('No assessment to export.', 'warning'); return; }
    var jsPDF = window.jspdf.jsPDF;
    var doc = new jsPDF();
    var y = 20;

    doc.setFontSize(18);
    doc.setTextColor(0, 48, 135);
    doc.text('Care Attend - Patient Risk Report', 14, y); y += 10;

    doc.setFontSize(10);
    doc.setTextColor(66, 85, 99);
    doc.text('Generated: ' + new Date().toLocaleString(), 14, y); y += 10;

    doc.setFontSize(14);
    doc.setTextColor(0, 48, 135);
    doc.text('Risk Assessment', 14, y); y += 8;

    var r = lastResult;
    doc.autoTable({
        startY: y,
        head: [['Metric', 'Value']],
        body: [
            ['Risk Score', r.percentage],
            ['Risk Tier', r.risk_tier],
            ['Age Group', r.age_group],
            ['Model', r.model_used || 'Logistic Regression'],
        ],
        theme: 'grid',
        headStyles: { fillColor: [0, 48, 135] },
    });
    y = doc.lastAutoTable.finalY + 10;

    if (r.shap_values && r.shap_values.length > 0) {
        doc.setFontSize(14);
        doc.setTextColor(0, 48, 135);
        doc.text('SHAP Risk Factors', 14, y); y += 8;

        doc.autoTable({
            startY: y,
            head: [['Factor', 'Impact', 'Direction']],
            body: r.shap_values.map(function(s) { return [s.label, s.value.toFixed(4), s.direction]; }),
            theme: 'grid',
            headStyles: { fillColor: [0, 48, 135] },
        });
        y = doc.lastAutoTable.finalY + 10;
    }

    if (r.nl_summary) {
        doc.setFontSize(12);
        doc.setTextColor(0, 48, 135);
        doc.text('Summary', 14, y); y += 6;
        doc.setFontSize(10);
        doc.setTextColor(66, 85, 99);
        var lines = doc.splitTextToSize(r.nl_summary, 180);
        doc.text(lines, 14, y);
    }

    doc.setFontSize(8);
    doc.setTextColor(150);
    doc.text('Care Attend | COM668 | Ulster University | GDPR Art 5(1)(c) Compliant | No patient data stored', 14, 285);

    doc.save('CareAttend_Patient_Report.pdf');
    showToast('PDF exported.', 'success');
}

function printResults() {
    window.print();
}


// ── Dark Mode Icon Update ──

function updateDarkModeIcon() {
    var icon = document.getElementById('dark-mode-icon');
    if (!icon) return;
    var isDark = document.body.classList.contains('dark-mode');
    icon.setAttribute('data-lucide', isDark ? 'sun' : 'moon');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

var _origToggleDark = toggleDarkMode;
toggleDarkMode = function() {
    _origToggleDark();
    updateDarkModeIcon();
};


// ── DOMContentLoaded Init ──

document.addEventListener('DOMContentLoaded', async function() {
    if (typeof lucide !== 'undefined') lucide.createIcons();
    updateDarkModeIcon();

    var savedToken = localStorage.getItem('careattend_token');
    var savedUser = localStorage.getItem('careattend_user');
    if (savedToken && savedUser) {
        try {
            var res = await fetch('/api/profile', {
                headers: { 'Authorization': 'Bearer ' + savedToken, 'Content-Type': 'application/json' },
            });
            if (res.ok) {
                authToken = savedToken;
                showMainApp(savedUser);
                addNotification('Session Restored', 'Welcome back, ' + savedUser + '.', 'success');
                return;
            }
            console.warn('Session restore failed:', res.status);
        } catch (err) {
            console.warn('Session restore error:', err.message);
        }
        localStorage.removeItem('careattend_token');
        localStorage.removeItem('careattend_user');
    }

    addNotification('Welcome to Care Attend', 'NHS Predictive Risk Assessment system ready. All data is session-scoped.', 'info');
});
