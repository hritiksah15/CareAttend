let riskGaugeChart = null;
let shapChart = null;
let riskHistoryChart = null;
let lastResult = null;
let authToken = null;
let sessionTimer = null;
let biasAuditData = null;
let riskHistory = []; // session-scoped risk trajectory (FR-09)
const SESSION_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes (NFR-06)

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

let loginNeeds2FA = false;

document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('login-username').value.trim();
    const password = document.getElementById('login-password').value;
    const totpCode = document.getElementById('login-2fa-code')?.value.trim() || null;

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
            loginNeeds2FA = true;
            document.getElementById('login-2fa-group').style.display = 'block';
            document.getElementById('login-2fa-code').focus();
            document.getElementById('login-submit-btn').textContent = 'VERIFY & LOG IN';
            showAuthError('login-error', '');
            document.getElementById('login-error').style.display = 'none';
            return;
        }

        if (res.ok && data.token) {
            authToken = data.token;
            loginNeeds2FA = false;
            document.getElementById('login-2fa-group').style.display = 'none';
            document.getElementById('login-2fa-code').value = '';
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
    document.getElementById('login-screen').style.display = 'none';
    document.getElementById('main-app').style.display = 'block';
    const initials = username.substring(0, 2).toUpperCase();
    document.getElementById('user-badge').textContent = initials + ' ' + username;
    resetSessionTimer();
}

async function openProfile() {
    document.getElementById('profile-overlay').style.display = 'flex';
    try {
        const res = await fetch('/api/profile', { headers: authHeaders() });
        if (res.ok) {
            const profile = await res.json();
            renderAccountCentre(profile);
        }
    } catch { /* use defaults */ }
    const initials = currentUsername.substring(0, 2).toUpperCase();
    document.getElementById('ac-avatar').textContent = initials;
    if (typeof lucide !== 'undefined') lucide.createIcons();
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
        document.getElementById('ac-pw-changed').textContent = `Last changed: ${d.toLocaleDateString('en-GB')}`;
    } else {
        document.getElementById('ac-pw-changed').textContent = 'Never changed';
    }

    const badge = document.getElementById('2fa-badge');
    if (profile.totpEnabled) {
        badge.className = 'ac-2fa-badge enabled';
        badge.innerHTML = '<i data-lucide="shield-check" style="width:14px;height:14px;"></i> Enabled';
        document.getElementById('2fa-setup-area').style.display = 'none';
        document.getElementById('2fa-qr-area').style.display = 'none';
        document.getElementById('2fa-disable-area').style.display = 'block';
    } else {
        badge.className = 'ac-2fa-badge disabled';
        badge.innerHTML = '<i data-lucide="shield-off" style="width:14px;height:14px;"></i> Disabled';
        document.getElementById('2fa-setup-area').style.display = 'block';
        document.getElementById('2fa-qr-area').style.display = 'none';
        document.getElementById('2fa-disable-area').style.display = 'none';
    }
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function switchAccountTab(tab) {
    document.querySelectorAll('.ac-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.ac-panel').forEach(p => p.classList.remove('active'));
    document.querySelector(`.ac-tab[onclick*="${tab}"]`).classList.add('active');
    document.getElementById(`ac-panel-${tab}`).classList.add('active');
    if (typeof lucide !== 'undefined') lucide.createIcons();
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
            showToast('Display name updated.', 'success');
        }
    } catch {
        showToast('Failed to update name.', 'error');
    }
}

async function handleChangePassword(e) {
    e.preventDefault();
    const currentPw = document.getElementById('ac-current-pw').value;
    const newPw = document.getElementById('ac-new-pw').value;
    const confirmPw = document.getElementById('ac-confirm-pw').value;

    if (newPw !== confirmPw) {
        showToast('New passwords do not match.', 'error');
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
            showToast('Password changed successfully.', 'success');
            document.getElementById('change-password-form').reset();
            document.getElementById('ac-pw-changed').textContent = `Last changed: ${new Date().toLocaleDateString('en-GB')}`;
        } else {
            showToast(data.error || 'Password change failed.', 'error');
        }
    } catch {
        showToast('Failed to change password.', 'error');
    }
}

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

            const qrContainer = document.getElementById('2fa-qr-container');
            qrContainer.innerHTML = '';
            if (typeof QRCode !== 'undefined') {
                new QRCode(qrContainer, {
                    text: data.uri,
                    width: 180,
                    height: 180,
                    colorDark: '#003087',
                    colorLight: '#ffffff',
                });
            }
        } else {
            showToast(data.error || '2FA setup failed.', 'error');
        }
    } catch {
        showToast('Failed to start 2FA setup.', 'error');
    }
}

async function verify2FA() {
    const code = document.getElementById('2fa-verify-code').value.trim();
    if (code.length !== 6) {
        showToast('Enter 6-digit code from authenticator app.', 'warning');
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
            showToast('2FA enabled! Your account is now more secure.', 'success', 5000);
            document.getElementById('2fa-qr-area').style.display = 'none';
            document.getElementById('2fa-disable-area').style.display = 'block';
            const badge = document.getElementById('2fa-badge');
            badge.className = 'ac-2fa-badge enabled';
            badge.innerHTML = '<i data-lucide="shield-check" style="width:14px;height:14px;"></i> Enabled';
            if (typeof lucide !== 'undefined') lucide.createIcons();
        } else {
            showToast(data.error || 'Verification failed.', 'error');
        }
    } catch {
        showToast('Verification failed.', 'error');
    }
}

async function disable2FA() {
    const pw = document.getElementById('2fa-disable-pw').value;
    if (!pw) {
        showToast('Enter password to disable 2FA.', 'warning');
        return;
    }
    try {
        const res = await fetch('/api/profile/2fa/disable', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ password: pw }),
        });
        const data = await res.json();
        if (res.ok) {
            showToast('2FA disabled.', 'info');
            document.getElementById('2fa-disable-area').style.display = 'none';
            document.getElementById('2fa-setup-area').style.display = 'block';
            document.getElementById('2fa-disable-pw').value = '';
            const badge = document.getElementById('2fa-badge');
            badge.className = 'ac-2fa-badge disabled';
            badge.innerHTML = '<i data-lucide="shield-off" style="width:14px;height:14px;"></i> Disabled';
            if (typeof lucide !== 'undefined') lucide.createIcons();
        } else {
            showToast(data.error || 'Failed to disable 2FA.', 'error');
        }
    } catch {
        showToast('Failed to disable 2FA.', 'error');
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
    clearSessionTimer();
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
        showToast('Session expired due to 30 minutes of inactivity.', 'warning', 5000);
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
    const tabBtn = document.querySelector(`[data-tab="${tabName}"]`);
    tabBtn.classList.add('active');
    tabBtn.setAttribute('aria-selected', 'true');
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
            showToast('Session expired. Please log in again.', 'warning');
            handleLogout();
        } else {
            showToast(result.error || 'Prediction failed.', 'error');
        }
    } catch {
        showToast('Connection error. Is the server running?', 'error');
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
            showToast('Session expired. Please log in again.', 'warning');
            handleLogout();
            return;
        }
        const data = await res.json();
        renderBiasResults(data);
        document.getElementById('bias-results').style.display = 'block';
    } catch {
        showToast('Bias audit failed. Is the server running?', 'error');
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
            showToast('Session expired. Please log in again.', 'warning');
            handleLogout();
            return;
        }

        if (!res.ok) {
            const err = await res.json();
            showToast(err.error || 'Batch processing failed', 'error');
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
        showToast('Batch upload failed. Check server connection.', 'error');
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
        showToast('Run bias audit first before exporting.', 'warning');
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
        showToast('Failed to submit feedback.', 'error');
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
        showToast('Dashboard load failed.', 'error');
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
    if (!nhsNum) { showToast('Enter an NHS number (e.g. NHS001)', 'warning'); return; }

    try {
        const res = await fetch(`/api/ehr/lookup/${nhsNum}`, { headers: authHeaders() });
        const data = await res.json();
        if (!res.ok) { showToast(data.error || 'Patient not found', 'error'); return; }

        const p = data.patient;
        document.getElementById('age').value = p.Age || '';
        document.getElementById('gender').value = p.Gender !== undefined ? p.Gender.toString() : '';
        document.getElementById('imd').value = p.IMDDecile || '';
        document.getElementById('priordna').value = p.PriorDNACount || '';
        document.getElementById('hypertension').checked = !!p.Hypertension;
        document.getElementById('diabetes').checked = !!p.Diabetes;
        document.getElementById('disability').checked = !!p.Disability;

        document.getElementById('age').dispatchEvent(new Event('input'));
        showToast(`Auto-filled from EHR: ${p.name} (${nhsNum})`, 'success');
    } catch {
        showToast('EHR lookup failed. Check server connection.', 'error');
    }
}

// ── Ethics Framework (Feature 19) ──

async function loadEthicsFramework() {
    try {
        const res = await fetch('/api/ethics-framework', { headers: authHeaders() });
        if (res.status === 401) { handleLogout(); return; }
        const data = await res.json();
        renderEthicsFramework(data);
    } catch { showToast('Failed to load ethics framework.', 'error'); }
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

async function runCrossValidation(e) {
    const btn = e ? e.target : document.querySelector('[onclick*="runCrossValidation"]');
    btn.disabled = true;
    btn.textContent = 'Running (may take 30s)...';

    try {
        const res = await fetch('/api/evaluation/cross-validation', {
            method: 'POST', headers: authHeaders(),
        });
        if (res.status === 401) { handleLogout(); return; }
        const data = await res.json();
        renderCVResults(data);
    } catch { showToast('Cross-validation failed.', 'error'); }
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

// ══════════════════════════════════════════════════════
// NOTIFICATION SYSTEM
// ══════════════════════════════════════════════════════

let notifications = [];

function toggleNotifications() {
    const dropdown = document.getElementById('notification-dropdown');
    const isVisible = dropdown.style.display !== 'none';
    dropdown.style.display = isVisible ? 'none' : 'block';
    if (!isVisible) {
        notifications.forEach(n => n.read = true);
        updateNotifBadge();
    }
}

document.addEventListener('click', (e) => {
    const wrapper = document.querySelector('.notif-wrapper');
    const dropdown = document.getElementById('notification-dropdown');
    if (wrapper && !wrapper.contains(e.target) && dropdown) {
        dropdown.style.display = 'none';
    }
});

function addNotification(title, desc, type) {
    const notif = {
        id: Date.now(),
        title,
        desc,
        type,
        time: new Date(),
        read: false,
    };
    notifications.unshift(notif);
    if (notifications.length > 20) notifications.pop();
    renderNotifications();
    updateNotifBadge();
}

function renderNotifications() {
    const list = document.getElementById('notif-list');
    if (notifications.length === 0) {
        list.innerHTML = '<div class="notif-empty">No notifications yet</div>';
        return;
    }
    list.innerHTML = notifications.map(n => {
        const iconMap = {
            'risk-high': 'alert-triangle',
            'risk-medium': 'alert-circle',
            'risk-low': 'check-circle',
            'info': 'info',
            'bias': 'scale',
        };
        const ago = timeAgo(n.time);
        return `
            <div class="notif-item ${n.read ? '' : 'unread'}">
                <div class="notif-icon ${n.type}"><i data-lucide="${iconMap[n.type] || 'info'}" style="width:16px;height:16px;"></i></div>
                <div class="notif-body">
                    <div class="notif-title">${n.title}</div>
                    <div class="notif-desc">${n.desc}</div>
                    <div class="notif-time">${ago}</div>
                </div>
            </div>
        `;
    }).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function updateNotifBadge() {
    const badge = document.getElementById('notif-badge');
    const unread = notifications.filter(n => !n.read).length;
    if (unread > 0) {
        badge.textContent = unread > 9 ? '9+' : unread;
        badge.style.display = 'flex';
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
    const seconds = Math.floor((new Date() - date) / 1000);
    if (seconds < 60) return 'Just now';
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    return `${Math.floor(hours / 24)}d ago`;
}

// ══════════════════════════════════════════════════════
// AI CHATBOT
// ══════════════════════════════════════════════════════

let chatbotOpen = false;

function toggleChatbot() {
    chatbotOpen = !chatbotOpen;
    const panel = document.getElementById('chatbot-panel');
    const fab = document.getElementById('chatbot-fab');
    panel.style.display = chatbotOpen ? 'flex' : 'none';
    fab.classList.toggle('active', chatbotOpen);
    if (chatbotOpen) {
        document.getElementById('chatbot-input').focus();
        if (typeof lucide !== 'undefined') lucide.createIcons();
    }
}

function sendSuggestion(text) {
    document.getElementById('chat-suggestions').style.display = 'none';
    appendChatMessage(text, 'user');
    showTypingIndicator();
    setTimeout(() => {
        removeTypingIndicator();
        const response = getChatbotResponse(text);
        appendChatMessage(response, 'bot');
    }, 800 + Math.random() * 600);
}

function sendChatMessage() {
    const input = document.getElementById('chatbot-input');
    const text = input.value.trim();
    if (!text) return;
    input.value = '';
    appendChatMessage(text, 'user');
    showTypingIndicator();
    setTimeout(() => {
        removeTypingIndicator();
        const response = getChatbotResponse(text);
        appendChatMessage(response, 'bot');
    }, 800 + Math.random() * 600);
}

function appendChatMessage(text, sender) {
    const container = document.getElementById('chatbot-messages');
    const avatarIcon = sender === 'bot' ? '<i data-lucide="bot" style="width:14px;height:14px;"></i>' : '<i data-lucide="user" style="width:14px;height:14px;"></i>';
    const msg = document.createElement('div');
    msg.className = `chat-msg ${sender}`;
    msg.innerHTML = `
        <div class="chat-avatar">${avatarIcon}</div>
        <div class="chat-bubble">${text}</div>
    `;
    container.appendChild(msg);
    container.scrollTop = container.scrollHeight;
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function showTypingIndicator() {
    const container = document.getElementById('chatbot-messages');
    const indicator = document.createElement('div');
    indicator.className = 'chat-msg bot';
    indicator.id = 'typing-indicator';
    indicator.innerHTML = `
        <div class="chat-avatar"><i data-lucide="bot" style="width:14px;height:14px;"></i></div>
        <div class="chat-bubble"><div class="typing-indicator"><div class="typing-dot"></div><div class="typing-dot"></div><div class="typing-dot"></div></div></div>
    `;
    container.appendChild(indicator);
    container.scrollTop = container.scrollHeight;
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function removeTypingIndicator() {
    const indicator = document.getElementById('typing-indicator');
    if (indicator) indicator.remove();
}

function getChatbotResponse(query) {
    const q = query.toLowerCase();

    if (q.includes('assess') || q.includes('patient') || q.includes('risk')) {
        return 'To assess a patient: Go to the <strong>Assessment</strong> tab, fill in demographics (age, gender), appointment details (lead time, prior DNAs), clinical flags, and social context (IMD decile). Click <strong>"Assess Risk"</strong> to get a prediction with SHAP explanations.';
    }
    if (q.includes('shap') || q.includes('explain') || q.includes('why')) {
        return '<strong>SHAP</strong> (SHapley Additive exPlanations) shows which factors contributed most to the prediction. Red bars increase risk, green bars reduce it. This makes the ML model transparent and auditable per NHS AI guidance.';
    }
    if (q.includes('bias') || q.includes('fair') || q.includes('ethic')) {
        return 'The <strong>Bias Monitor</strong> tab runs fairness audits across age, gender, and IMD groups. It checks Demographic Parity and Equalised Odds against a 0.10 threshold per NHS AI ethics guidance. You can export a PDF audit report.';
    }
    if (q.includes('privacy') || q.includes('gdpr') || q.includes('data')) {
        return 'Care Attend is <strong>GDPR Article 5(1)(c)</strong> compliant. No patient data is stored — all information is processed in-session only and cleared on browser close. Session timeout is 30 minutes of inactivity.';
    }
    if (q.includes('batch') || q.includes('upload') || q.includes('csv')) {
        return 'The <strong>Batch Upload</strong> tab lets you upload a CSV with up to 100 patient records for bulk risk assessment. Required columns: Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile. Results download as CSV.';
    }
    if (q.includes('dark') || q.includes('theme') || q.includes('mode')) {
        return 'Click the <strong>moon icon</strong> in the header to toggle dark mode. Your preference is saved in local storage and persists across sessions.';
    }
    if (q.includes('ehr') || q.includes('auto-fill') || q.includes('nhs number')) {
        return 'Use the <strong>EHR Quick Lookup</strong> bar on the Assessment tab. Enter an NHS number (e.g., NHS001) and click "Auto-fill from EHR" to populate patient details from the mock EHR system.';
    }
    if (q.includes('intervention') || q.includes('recommend') || q.includes('action')) {
        return 'After a risk assessment, the system shows <strong>contextual interventions</strong> based on the patient\'s risk profile and age group. Priority 1 (red) = urgent, Priority 2 (amber) = important, Priority 3 (green) = preventive.';
    }
    if (q.includes('cross') || q.includes('validation') || q.includes('model')) {
        return 'The <strong>Ethics</strong> tab includes 5-fold cross-validation with bootstrap 95% CIs and McNemar significance tests. This compares Random Forest, Logistic Regression, and other models to justify model selection.';
    }
    if (q.includes('language') || q.includes('welsh') || q.includes('urdu') || q.includes('polish')) {
        return 'Care Attend supports <strong>4 languages</strong>: English (EN), Welsh (CY), Urdu (UR), and Polish (PL). Use the language selector in the header to switch. This meets NHS Wales accessibility requirements.';
    }
    if (q.includes('logout') || q.includes('session') || q.includes('timeout')) {
        return 'Sessions timeout after <strong>30 minutes</strong> of inactivity (NFR-06). All session data is cleared on logout. Click "Log Out" in the header or let the timeout trigger automatically.';
    }
    if (q.includes('hello') || q.includes('hi') || q.includes('hey')) {
        return 'Hello! How can I help you today? I can assist with risk assessments, explain SHAP values, guide you through bias monitoring, or answer questions about data privacy.';
    }
    if (q.includes('thank')) {
        return 'You\'re welcome! Let me know if you need anything else. I\'m here to help you get the most out of Care Attend.';
    }

    return 'I can help with: <strong>patient assessments</strong>, <strong>SHAP explanations</strong>, <strong>bias monitoring</strong>, <strong>batch uploads</strong>, <strong>data privacy</strong>, and <strong>app navigation</strong>. Could you rephrase your question?';
}

// ══════════════════════════════════════════════════════
// AUTO-NOTIFICATIONS ON KEY EVENTS
// ══════════════════════════════════════════════════════

const _originalRenderResults = renderResults;
renderResults = function(result) {
    _originalRenderResults(result);
    const tier = result.risk_tier.toLowerCase();
    const pct = result.percentage;
    if (tier === 'high') {
        addNotification(
            'High Risk Patient Detected',
            `Patient (Age ${result.patient_summary.Age}) scored ${pct}% DNA risk. Immediate intervention recommended.`,
            'risk-high'
        );
    } else if (tier === 'medium') {
        addNotification(
            'Medium Risk Assessment',
            `Patient (Age ${result.patient_summary.Age}) scored ${pct}% DNA risk. Consider preventive measures.`,
            'risk-medium'
        );
    } else {
        addNotification(
            'Low Risk Assessment Complete',
            `Patient (Age ${result.patient_summary.Age}) scored ${pct}% DNA risk.`,
            'risk-low'
        );
    }
};

const _originalRunBiasAudit = runBiasAudit;
runBiasAudit = async function() {
    await _originalRunBiasAudit();
    if (biasAuditData) {
        const failures = [];
        if (biasAuditData.age_group?.dp_status === 'Fail') failures.push('Age DP');
        if (biasAuditData.gender?.dp_status === 'Fail') failures.push('Gender DP');
        if (biasAuditData.imd_band?.dp_status === 'Fail') failures.push('IMD DP');
        if (failures.length > 0) {
            addNotification(
                'Bias Alert: Threshold Exceeded',
                `Fairness failures detected: ${failures.join(', ')}. Review bias dashboard.`,
                'bias'
            );
        } else {
            addNotification(
                'Bias Audit Complete',
                'All fairness metrics within acceptable thresholds.',
                'info'
            );
        }
    }
};

// ══════════════════════════════════════════════════════
// INITIALIZE LUCIDE ICONS
// ══════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════
// TOAST NOTIFICATION SYSTEM (replaces alert())
// ══════════════════════════════════════════════════════

function showToast(message, type = 'info', duration = 4000) {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const iconMap = {
        success: 'check-circle',
        error: 'alert-circle',
        warning: 'alert-triangle',
        info: 'info',
    };

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.style.position = 'relative';
    toast.innerHTML = `
        <div class="toast-icon"><i data-lucide="${iconMap[type] || 'info'}" style="width:16px;height:16px;"></i></div>
        <span class="toast-msg">${message}</span>
        <button class="toast-close" onclick="this.parentElement.classList.add('toast-exit');setTimeout(()=>this.parentElement.remove(),300)">&times;</button>
        <div class="toast-progress"></div>
    `;
    container.appendChild(toast);
    if (typeof lucide !== 'undefined') lucide.createIcons();

    setTimeout(() => {
        if (toast.parentElement) {
            toast.classList.add('toast-exit');
            setTimeout(() => toast.remove(), 300);
        }
    }, duration);
}

// ══════════════════════════════════════════════════════
// SESSION COUNTDOWN TIMER
// ══════════════════════════════════════════════════════

let sessionCountdownInterval = null;
let sessionExpiresAt = null;

const _origResetTimer = resetSessionTimer;
resetSessionTimer = function() {
    _origResetTimer();
    sessionExpiresAt = Date.now() + SESSION_TIMEOUT_MS;
    startCountdown();
};

function startCountdown() {
    if (sessionCountdownInterval) clearInterval(sessionCountdownInterval);
    sessionCountdownInterval = setInterval(updateCountdown, 1000);
}

function updateCountdown() {
    if (!sessionExpiresAt) return;
    const remaining = Math.max(0, sessionExpiresAt - Date.now());
    const mins = Math.floor(remaining / 60000);
    const secs = Math.floor((remaining % 60000) / 1000);
    const display = document.getElementById('session-countdown');
    const timer = document.getElementById('session-timer');
    if (display) display.textContent = `${mins}:${secs.toString().padStart(2, '0')}`;
    if (timer) {
        timer.classList.remove('warning', 'critical');
        if (mins < 2) timer.classList.add('critical');
        else if (mins < 5) timer.classList.add('warning');
    }
    if (remaining <= 0) {
        clearInterval(sessionCountdownInterval);
    }
}

// ══════════════════════════════════════════════════════
// DARK MODE ICON TOGGLE
// ══════════════════════════════════════════════════════

const _origToggleDark = toggleDarkMode;
toggleDarkMode = function() {
    _origToggleDark();
    updateDarkModeIcon();
};

function updateDarkModeIcon() {
    const icon = document.getElementById('dark-mode-icon');
    if (icon) {
        const isDark = document.body.classList.contains('dark-mode');
        icon.setAttribute('data-lucide', isDark ? 'sun' : 'moon');
        if (typeof lucide !== 'undefined') lucide.createIcons();
    }
}

// ══════════════════════════════════════════════════════
// KEYBOARD SHORTCUTS
// ══════════════════════════════════════════════════════

document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') return;
    if (!authToken) return;

    const tabs = ['assessment', 'results', 'dashboard', 'batch', 'bias', 'ethics'];
    const key = e.key;

    if (key >= '1' && key <= '6') {
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
    } else if (key === 'Escape') {
        closeProfile();
        closeShortcuts();
        if (chatbotOpen) toggleChatbot();
        document.getElementById('notification-dropdown').style.display = 'none';
    }
});

function openShortcuts() {
    document.getElementById('shortcuts-overlay').style.display = 'flex';
    if (typeof lucide !== 'undefined') lucide.createIcons();
}
function closeShortcuts() {
    document.getElementById('shortcuts-overlay').style.display = 'none';
}

// ══════════════════════════════════════════════════════
// PATIENT RISK REPORT PDF EXPORT
// ══════════════════════════════════════════════════════

function exportPatientPDF() {
    if (!lastResult) {
        showToast('No assessment to export. Run an assessment first.', 'warning');
        return;
    }
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    const r = lastResult;
    const p = r.patient_summary;
    let y = 20;

    doc.setFontSize(20);
    doc.setTextColor(0, 48, 135);
    doc.text('Care Attend - Patient Risk Report', 14, y);
    y += 10;

    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Generated: ${new Date().toLocaleString()} | Session: ${r.sessionId?.substring(0, 8) || '---'}`, 14, y);
    y += 12;

    doc.setFontSize(14);
    doc.setTextColor(0, 48, 135);
    doc.text('Risk Assessment Result', 14, y);
    y += 8;

    const tierColors = { High: [218,41,28], Medium: [184,134,11], Low: [0,127,59] };
    doc.setFontSize(28);
    doc.setTextColor(...(tierColors[r.risk_tier] || [0,0,0]));
    doc.text(`${r.percentage}% — ${r.risk_tier.toUpperCase()} RISK`, 14, y);
    y += 14;

    doc.setFontSize(12);
    doc.setTextColor(0, 48, 135);
    doc.text('Patient Summary', 14, y);
    y += 6;
    doc.autoTable({
        startY: y,
        head: [['Field', 'Value']],
        body: [
            ['Age', `${p.Age} (${r.age_group})`],
            ['Gender', p.Gender === 1 ? 'Male' : 'Female'],
            ['IMD Decile', p.IMDDecile.toString()],
            ['Lead Time', `${p.AppointmentLeadTimeDays} days`],
            ['Prior DNAs', p.PriorDNACount.toString()],
            ['SMS Received', p.SMSReceived ? 'Yes' : 'No'],
            ['Hypertension', p.Hypertension ? 'Yes' : 'No'],
            ['Diabetes', p.Diabetes ? 'Yes' : 'No'],
        ],
        theme: 'grid',
        headStyles: { fillColor: [0, 48, 135] },
        margin: { left: 14 },
    });
    y = doc.lastAutoTable.finalY + 10;

    doc.setFontSize(12);
    doc.setTextColor(0, 48, 135);
    doc.text('SHAP Feature Attribution (Top Factors)', 14, y);
    y += 6;
    doc.autoTable({
        startY: y,
        head: [['Factor', 'SHAP Value', 'Direction']],
        body: r.shap_values.slice(0, 5).map(s => [
            s.label,
            s.value.toFixed(4),
            s.value > 0 ? 'Increases Risk' : 'Reduces Risk',
        ]),
        theme: 'grid',
        headStyles: { fillColor: [0, 48, 135] },
        margin: { left: 14 },
    });
    y = doc.lastAutoTable.finalY + 10;

    if (r.interventions && r.interventions.length > 0) {
        doc.setFontSize(12);
        doc.setTextColor(0, 48, 135);
        doc.text('Recommended Interventions', 14, y);
        y += 6;
        doc.autoTable({
            startY: y,
            head: [['Priority', 'Action', 'Details']],
            body: r.interventions.map(iv => [
                `P${iv.priority}`,
                iv.title,
                iv.description,
            ]),
            theme: 'grid',
            headStyles: { fillColor: [0, 48, 135] },
            margin: { left: 14 },
            columnStyles: { 2: { cellWidth: 90 } },
        });
        y = doc.lastAutoTable.finalY + 10;
    }

    if (r.nl_summary) {
        if (y > 240) { doc.addPage(); y = 20; }
        doc.setFontSize(12);
        doc.setTextColor(0, 48, 135);
        doc.text('Plain-English Summary', 14, y);
        y += 6;
        doc.setFontSize(10);
        doc.setTextColor(66, 85, 99);
        const splitNL = doc.splitTextToSize(r.nl_summary, 180);
        doc.text(splitNL, 14, y);
    }

    doc.setFontSize(8);
    doc.setTextColor(150);
    doc.text('Care Attend | COM668 | Ulster University | Session-scoped only | GDPR Art 5(1)(c)', 14, 285);

    doc.save(`CareAttend_Risk_Report_${r.sessionId?.substring(0, 8) || 'unknown'}.pdf`);
    showToast('Risk report exported as PDF.', 'success');
}

function printResults() {
    window.print();
}

// ══════════════════════════════════════════════════════
// REPLACE alert() WITH TOAST
// ══════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', () => {
    if (typeof lucide !== 'undefined') {
        lucide.createIcons();
    }
    updateDarkModeIcon();
    addNotification(
        'Welcome to Care Attend',
        'NHS Predictive Risk Assessment system ready. All data is session-scoped.',
        'info'
    );
});
