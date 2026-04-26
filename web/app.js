/**
 * Federal SAVE Act — Computational Amicus Explorer
 * Interactive proof-dependency graph viewer with assumption toggles.
 *
 * No external dependencies. No build step. No framework.
 */

(function () {
  'use strict';

  // ---- State ----
  let data = null;
  let selectedNodeId = null;
  let activeAssumptions = new Set();
  let dimmedNodes = new Set();
  let activeDrawer = null;
  let activePreset = 'compare';
  let reviewerMode = false;

  // ---- Preset definitions ----
  const PRESETS = {
    compare: {
      label: 'Compare Both',
      hyps: ['hyp-no-fault', 'hyp-material-burden', 'hyp-burden-not-severe', 'hyp-adequate-alt',
             'hyp-mandatory', 'hyp-discretionary', 'hyp-election-integrity', 'hyp-reasonable', 'hyp-severe-defeats'],
    },
    challenger: {
      label: 'Challenger',
      hyps: ['hyp-no-fault', 'hyp-material-burden', 'hyp-discretionary', 'hyp-severe-defeats'],
    },
    government: {
      label: 'Government',
      hyps: ['hyp-burden-not-severe', 'hyp-adequate-alt', 'hyp-mandatory',
             'hyp-election-integrity', 'hyp-reasonable'],
    },
    neutral: {
      label: 'Neutral',
      hyps: [],
    },
    highrisk: {
      label: 'High-Risk',
      hyps: ['hyp-no-fault', 'hyp-material-burden', 'hyp-burden-not-severe'],
    },
  };

  // ---- Node type display names ----
  const TYPE_LABELS = {
    LEGAL_SOURCE: 'Legal Source',
    TRACEABILITY_ARTIFACT: 'Traceability',
    SCENARIO_FACT: 'Scenario Fact',
    TEXT_FACT: 'Text Fact',
    EMPIRICAL_ASSUMPTION: 'Empirical Assumption',
    INTERPRETIVE_ASSUMPTION: 'Interpretive Assumption',
    DOCTRINAL_ASSUMPTION: 'Doctrinal Assumption',
    BRIDGE_RULE: 'Bridge Rule',
    PROCESS_MODEL: 'Process Model',
    DOCUMENT_MODEL: 'Document Model',
    BURDEN_MODEL: 'Burden Model',
    HINGE_MODEL: 'Hinge Model',
    EXISTENTIAL_MODEL: 'Existential Model',
    LEMMA: 'Lemma',
    THEOREM: 'Theorem',
    FINAL_CONCLUSION: 'Final Conclusion',
  };

  // ---- Type → CSS color var ----
  const TYPE_COLORS = {
    LEGAL_SOURCE: '#4A90D9',
    TRACEABILITY_ARTIFACT: '#708090',
    SCENARIO_FACT: '#5DADE2',
    TEXT_FACT: '#4A90D9',
    EMPIRICAL_ASSUMPTION: '#E8A838',
    INTERPRETIVE_ASSUMPTION: '#9B59B6',
    DOCTRINAL_ASSUMPTION: '#8E44AD',
    BRIDGE_RULE: '#1ABC9C',
    PROCESS_MODEL: '#3498DB',
    DOCUMENT_MODEL: '#3498DB',
    BURDEN_MODEL: '#3498DB',
    HINGE_MODEL: '#F39C12',
    EXISTENTIAL_MODEL: '#3498DB',
    LEMMA: '#1ABC9C',
    THEOREM: '#2ECC71',
    FINAL_CONCLUSION: '#E74C3C',
  };

  // ---- Boot ----
  async function init() {
    try {
      const resp = await fetch('data/explorer.json');
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      data = await resp.json();
    } catch (err) {
      document.getElementById('graph-container').innerHTML =
        `<p style="color:#E74C3C;padding:40px;">Failed to load explorer data: ${err.message}<br>Run <code>python tools/build_explorer_data.py</code> first.</p>`;
      return;
    }

    renderAuditBar();
    renderControls();
    renderGraph();
    renderFooter();

    // Initialize all hypotheticals as active
    data.hypotheticals.forEach(h => activeAssumptions.add(h.id));

    // Bind filter checkboxes
    document.getElementById('filter-axiom-free').addEventListener('change', renderGraph);
    document.getElementById('filter-high-risk').addEventListener('change', renderGraph);
    document.getElementById('filter-challenger').addEventListener('change', renderGraph);
    document.getElementById('filter-government').addEventListener('change', renderGraph);
    document.getElementById('filter-neutral').addEventListener('change', renderGraph);

    document.getElementById('warning-close').addEventListener('click', () => {
      document.getElementById('warning-banner').classList.add('hidden');
    });

    // Audit stat drill-down
    document.querySelectorAll('.audit-stat-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const key = btn.dataset.audit;
        toggleAuditDrawer(key);
      });
    });
    document.getElementById('audit-drawer-close').addEventListener('click', closeAuditDrawer);

    // Preset buttons
    setupPresets();

    // Reviewer mode toggle
    setupReviewerMode();

    // About modal
    const modal = document.getElementById('about-modal');
    const openModal = () => modal.classList.remove('hidden');
    const closeModal = () => { modal.classList.add('hidden'); localStorage.setItem('explorer-seen', '1'); };

    document.getElementById('about-btn').addEventListener('click', openModal);
    document.getElementById('modal-close').addEventListener('click', closeModal);
    document.getElementById('modal-got-it').addEventListener('click', closeModal);
    modal.addEventListener('click', (e) => { if (e.target === modal) closeModal(); });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        if (!modal.classList.contains('hidden')) closeModal();
        if (activeDrawer) closeAuditDrawer();
      }
    });

    // Show on first visit
    if (!localStorage.getItem('explorer-seen')) {
      openModal();
    }

    // Mobile panel toggles
    setupMobileToggles();

    // Initial scenario status
    updateScenarioStatus();
  }

  // ---- Preset Buttons ----
  function setupPresets() {
    document.querySelectorAll('.preset-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        applyPreset(btn.dataset.preset);
      });
    });
    // Mark default preset active
    updatePresetHighlight();
  }

  function applyPreset(name) {
    const preset = PRESETS[name];
    if (!preset) return;

    activePreset = name;
    activeAssumptions.clear();
    preset.hyps.forEach(id => activeAssumptions.add(id));

    // Update all checkboxes to match
    data.hypotheticals.forEach(h => {
      const cb = document.getElementById(`hyp-${h.id}`);
      if (cb) cb.checked = activeAssumptions.has(h.id);
    });

    // Check mutual exclusion warning
    checkMutualExclusion();

    recalculateDimming();
    updateNodeStates();
    updatePresetHighlight();
    updateScenarioStatus();
  }

  function updatePresetHighlight() {
    document.querySelectorAll('.preset-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.preset === activePreset);
    });
  }

  // ---- Reviewer Mode ----
  function setupReviewerMode() {
    const toggle = document.getElementById('reviewer-mode');
    if (!toggle) return;
    toggle.addEventListener('change', () => {
      reviewerMode = toggle.checked;
      document.body.classList.toggle('reviewer-active', reviewerMode);
    });
  }

  function setupMobileToggles() {
    const toggleLeft = document.getElementById('toggle-hypotheticals');
    const toggleRight = document.getElementById('toggle-details');
    const panelLeft = document.getElementById('panel-left');
    const panelRight = document.getElementById('panel-right');

    if (!toggleLeft || !toggleRight) return;

    toggleLeft.addEventListener('click', () => {
      const isOpen = panelLeft.classList.contains('mobile-open');
      panelLeft.classList.toggle('mobile-open');
      toggleLeft.classList.toggle('active');
      // Close other panel
      if (!isOpen) {
        panelRight.classList.remove('mobile-open');
        toggleRight.classList.remove('active');
      }
    });

    toggleRight.addEventListener('click', () => {
      const isOpen = panelRight.classList.contains('mobile-open');
      panelRight.classList.toggle('mobile-open');
      toggleRight.classList.toggle('active');
      // Close other panel
      if (!isOpen) {
        panelLeft.classList.remove('mobile-open');
        toggleLeft.classList.remove('active');
      }
    });
  }

  // ---- Audit Bar ----
  function renderAuditBar() {
    const m = data.meta;
    document.getElementById('stat-books').textContent = m.books_certified;
    document.getElementById('stat-theorems').textContent = m.theorems;
    document.getElementById('stat-axioms').textContent = m.axioms;
    document.getElementById('stat-existentials').textContent = m.defun_sk_existentials;
  }

  // ---- Footer ----
  function renderFooter() {
    document.getElementById('footer-version').textContent = `v${data.meta.version}`;
  }

  // ---- Audit Drawer ----
  function toggleAuditDrawer(key) {
    const drawer = document.getElementById('audit-drawer');

    // If same drawer is open, close it
    if (activeDrawer === key) {
      closeAuditDrawer();
      return;
    }

    // Highlight active stat
    document.querySelectorAll('.audit-stat-btn').forEach(b => b.classList.remove('active'));
    const activeBtn = document.querySelector(`.audit-stat-btn[data-audit="${key}"]`);
    if (activeBtn) activeBtn.classList.add('active');

    activeDrawer = key;
    const titleEl = document.getElementById('audit-drawer-title');
    const contentEl = document.getElementById('audit-drawer-content');

    switch (key) {
      case 'books':   titleEl.textContent = `${data.meta.books_certified} Certified ACL2 Books`; renderBooksDrawer(contentEl); break;
      case 'theorems': titleEl.textContent = `${data.meta.theorems} Q.E.D. Theorems`; renderTheoremsDrawer(contentEl); break;
      case 'axioms':  titleEl.textContent = `${data.meta.axioms} Source-Traced Axioms`; renderAxiomsDrawer(contentEl); break;
      case 'existentials': titleEl.textContent = `${data.meta.defun_sk_existentials} Existential Propositions (defun-sk)`; renderExistentialsDrawer(contentEl); break;
    }

    // Open the drawer (CSS handles the animation via max-height)
    drawer.classList.add('open');
  }

  function closeAuditDrawer() {
    const drawer = document.getElementById('audit-drawer');
    drawer.classList.remove('open');
    document.querySelectorAll('.audit-stat-btn').forEach(b => b.classList.remove('active'));
    activeDrawer = null;
  }

  function renderBooksDrawer(container) {
    const ad = data.audit_details;
    if (!ad || !ad.books) { container.innerHTML = '<p>No book data available.</p>'; return; }

    const clean = ad.books.filter(b => b.clean);
    const axiom = ad.books.filter(b => !b.clean);

    let html = '<div class="drawer-summary">';
    html += `<span class="drawer-chip chip-clean">${clean.length} clean (no axioms)</span>`;
    html += `<span class="drawer-chip chip-axiom">${axiom.length} defaxiom-chain</span>`;
    html += '</div>';

    html += '<table class="drawer-table">';
    html += '<thead><tr><th>Book</th><th>Layer</th><th>Theorems</th><th>Axioms</th><th>Status</th></tr></thead><tbody>';
    ad.books.forEach(b => {
      const statusClass = b.clean ? 'status-clean' : 'status-axiom';
      const statusLabel = b.clean ? 'Clean' : 'defaxioms-okp';
      const shortName = b.name.replace('federal_save_act_', '');
      html += `<tr>`;
      html += `<td class="mono">${shortName}</td>`;
      html += `<td class="center">${b.layer}</td>`;
      html += `<td class="center">${b.theorems}</td>`;
      html += `<td class="center">${b.axioms}</td>`;
      html += `<td><span class="table-badge ${statusClass}">${statusLabel}</span></td>`;
      html += `</tr>`;
    });
    html += '</tbody></table>';
    container.innerHTML = html;
  }

  function renderTheoremsDrawer(container) {
    const ad = data.audit_details;
    if (!ad || !ad.theorems_by_book) { container.innerHTML = '<p>No theorem data available.</p>'; return; }

    let totalCount = 0;
    Object.values(ad.theorems_by_book).forEach(arr => totalCount += arr.length);

    let html = `<div class="drawer-summary"><span class="drawer-chip chip-theorem">${totalCount} theorems across ${Object.keys(ad.theorems_by_book).length} books</span></div>`;

    for (const [book, thms] of Object.entries(ad.theorems_by_book)) {
      const shortName = book.replace('federal_save_act_', '');
      const bookInfo = ad.books.find(b => b.name === book);
      const isClean = bookInfo ? bookInfo.clean : false;
      html += `<div class="drawer-book-group">`;
      html += `<div class="drawer-book-header">`;
      html += `<span class="mono">${shortName}</span>`;
      html += `<span class="drawer-count">${thms.length}</span>`;
      if (isClean) html += `<span class="table-badge status-clean">0 Axioms</span>`;
      html += `</div>`;
      html += `<div class="drawer-theorem-list">`;
      thms.forEach(t => {
        html += `<span class="drawer-theorem-name">${t}</span>`;
      });
      html += `</div></div>`;
    }
    container.innerHTML = html;
  }

  function renderAxiomsDrawer(container) {
    const ad = data.audit_details;
    if (!ad || !ad.axioms_by_book) { container.innerHTML = '<p>No axiom data available.</p>'; return; }

    let totalCount = 0;
    Object.values(ad.axioms_by_book).forEach(arr => totalCount += arr.length);

    // Count by label
    const labelCounts = {};
    Object.values(ad.axioms_by_book).forEach(arr => {
      arr.forEach(ax => {
        const lbl = ax.label || 'UNKNOWN';
        labelCounts[lbl] = (labelCounts[lbl] || 0) + 1;
      });
    });

    let html = '<div class="drawer-summary">';
    for (const [lbl, cnt] of Object.entries(labelCounts)) {
      const cls = labelChipClass(lbl);
      html += `<span class="drawer-chip ${cls}">${cnt} ${lbl.replace(/_/g, ' ').toLowerCase()}</span>`;
    }
    html += '</div>';

    for (const [book, axms] of Object.entries(ad.axioms_by_book)) {
      const shortName = book.replace('federal_save_act_', '');
      html += `<div class="drawer-book-group">`;
      html += `<div class="drawer-book-header">`;
      html += `<span class="mono">${shortName}</span>`;
      html += `<span class="drawer-count">${axms.length}</span>`;
      html += `</div>`;
      html += `<div class="drawer-axiom-list">`;
      axms.forEach(ax => {
        const labelCls = labelChipClass(ax.label);
        html += `<div class="drawer-axiom-row">`;
        html += `<span class="drawer-axiom-name mono">${ax.name}</span>`;
        html += `<span class="drawer-chip-small ${labelCls}">${(ax.label || '').replace(/_/g, ' ')}</span>`;
        if (ax.source_id && ax.source_id !== 'n/a') html += `<span class="drawer-axiom-source">${ax.source_id}</span>`;
        if (ax.clause_text) html += `<div class="drawer-axiom-clause">${ax.clause_text}</div>`;
        html += `</div>`;
      });
      html += `</div></div>`;
    }
    container.innerHTML = html;
  }

  function renderExistentialsDrawer(container) {
    const ad = data.audit_details;
    if (!ad || !ad.existentials) { container.innerHTML = '<p>No existential data available.</p>'; return; }

    let html = `<div class="drawer-summary"><span class="drawer-chip chip-existential">${ad.existentials.length} defun-sk Skolemized existential propositions</span></div>`;
    html += '<div class="drawer-existential-list">';
    ad.existentials.forEach(ex => {
      const shortBook = ex.book.replace('federal_save_act_', '');
      html += `<div class="drawer-existential-row">`;
      html += `<span class="drawer-existential-name mono">${ex.name}</span>`;
      html += `<span class="drawer-existential-book">${shortBook}</span>`;
      html += `</div>`;
    });
    html += '</div>';
    container.innerHTML = html;
  }

  function labelChipClass(label) {
    switch (label) {
      case 'SCENARIO_FACT': return 'chip-scenario';
      case 'TEXT_FACT': return 'chip-text';
      case 'BRIDGE_RULE': return 'chip-bridge';
      case 'PROHIBITION': return 'chip-text';
      case 'EMPIRICAL_ASSUMPTION': return 'chip-empirical';
      case 'INTERPRETIVE_ASSUMPTION': return 'chip-interpretive';
      case 'INTERPRETATION_CHALLENGER': return 'chip-challenger';
      case 'INTERPRETATION_GOVERNMENT': return 'chip-government';
      case 'DOCTRINAL_RULE': return 'chip-doctrinal';
      default: return 'chip-neutral';
    }
  }

  // ---- Controls ----
  function renderControls() {
    const container = document.getElementById('controls-container');
    container.innerHTML = '';

    // Group hypotheticals by category
    const groups = {};
    data.hypotheticals.forEach(h => {
      if (!groups[h.category]) groups[h.category] = [];
      groups[h.category].push(h);
    });

    for (const [category, items] of Object.entries(groups)) {
      const groupEl = document.createElement('div');
      groupEl.className = 'control-group';

      const titleEl = document.createElement('div');
      titleEl.className = 'control-group-title';
      titleEl.textContent = category;
      groupEl.appendChild(titleEl);

      items.forEach(h => {
        const itemEl = document.createElement('label');
        itemEl.className = 'control-item';

        const cb = document.createElement('input');
        cb.type = 'checkbox';
        cb.checked = true;
        cb.id = `hyp-${h.id}`;
        cb.addEventListener('change', () => onToggleHypothetical(h, cb.checked));

        const labelEl = document.createElement('span');
        labelEl.className = 'control-label';
        labelEl.textContent = h.label;

        const pathEl = document.createElement('span');
        pathEl.className = `control-path path-${h.path}`;
        pathEl.textContent = h.path;

        itemEl.appendChild(cb);
        itemEl.appendChild(labelEl);
        itemEl.appendChild(pathEl);
        groupEl.appendChild(itemEl);
      });

      container.appendChild(groupEl);
    }
  }

  // ---- Toggle Hypothetical ----
  function onToggleHypothetical(hyp, isChecked) {
    if (isChecked) {
      activeAssumptions.add(hyp.id);
    } else {
      activeAssumptions.delete(hyp.id);
    }

    // Manual toggle clears active preset
    activePreset = null;
    updatePresetHighlight();

    // Check mutual exclusion warning
    checkMutualExclusion();

    // Recalculate dimmed nodes
    recalculateDimming();

    // Re-render graph with current state
    updateNodeStates();
  }

  function checkMutualExclusion() {
    const banner = document.getElementById('warning-banner');
    const text = document.getElementById('warning-text');

    // Check if both mandatory and discretionary are selected
    const mandatoryHyp = data.hypotheticals.find(h => h.id === 'hyp-mandatory');
    const discretionaryHyp = data.hypotheticals.find(h => h.id === 'hyp-discretionary');

    if (mandatoryHyp && discretionaryHyp) {
      const bothActive = activeAssumptions.has('hyp-mandatory') && activeAssumptions.has('hyp-discretionary');
      if (bothActive) {
        text.textContent = 'The mandatory and discretionary readings are competing interpretations. The model treats them as separate conditional paths.';
        banner.classList.remove('hidden');
        return;
      }
    }

    banner.classList.add('hidden');
  }

  // ---- Dimming Engine ----
  function recalculateDimming() {
    dimmedNodes.clear();

    // Step 1: Find which axiom/assumption nodes are unsupported
    const unsupportedAxioms = new Set();
    data.hypotheticals.forEach(h => {
      if (!activeAssumptions.has(h.id)) {
        h.controls.forEach(axId => unsupportedAxioms.add(axId));
      }
    });

    // Mark unsupported axiom nodes as dimmed
    unsupportedAxioms.forEach(id => dimmedNodes.add(id));

    // Step 2: Forward-propagate dimming through dependency edges.
    // A node becomes dimmed if ALL of its non-contested, non-negated incoming
    // support edges come from dimmed nodes.
    // Exception: axiom-free structural theorems are never dimmed.
    let changed = true;
    const maxIter = 50;
    let iter = 0;
    while (changed && iter < maxIter) {
      changed = false;
      iter++;
      data.nodes.forEach(node => {
        if (dimmedNodes.has(node.id)) return;
        if (node.axiom_free) return; // Never dim axiom-free theorems

        // Get all incoming support edges (not contests/negates)
        const supportEdges = data.edges.filter(e =>
          e.to === node.id &&
          e.relation !== 'contests' &&
          e.relation !== 'negates'
        );

        if (supportEdges.length === 0) return; // No incoming support = keep visible

        // Check if ALL support edges come from dimmed nodes
        const allSupportDimmed = supportEdges.every(e => dimmedNodes.has(e.from));
        if (allSupportDimmed) {
          dimmedNodes.add(node.id);
          changed = true;
        }
      });
    }

    // Step 3: Special handling for final conclusions.
    // A conclusion should be marked "unsupported" if ANY of its
    // path-specific direct supporters are dimmed.
    // This is handled by updateConclusionStatuses, not by dimming the node itself.
  }

  function updateNodeStates() {
    // Update all node elements
    data.nodes.forEach(node => {
      const el = document.getElementById(`node-${node.id}`);
      if (!el) return;

      if (dimmedNodes.has(node.id)) {
        el.classList.add('dimmed');
        el.classList.remove('highlighted');
      } else {
        el.classList.remove('dimmed');
      }
    });

    // Update conclusion status badges
    updateConclusionStatuses();
    updateScenarioStatus();
  }

  function updateConclusionStatuses() {
    const conclusions = data.nodes.filter(n => n.type === 'FINAL_CONCLUSION');
    conclusions.forEach(concl => {
      const statusEl = document.getElementById(`status-${concl.id}`);
      if (!statusEl) return;

      // If the conclusion itself is dimmed (all support gone)
      if (dimmedNodes.has(concl.id)) {
        statusEl.textContent = 'Unsupported';
        statusEl.className = 'conclusion-status status-unsupported';
        return;
      }

      // Check path-specific support: are any of the path-matching
      // hypotheticals for this conclusion turned off?
      const conclPath = concl.path; // 'challenger' or 'government'
      const pathHyps = data.hypotheticals.filter(h => h.path === conclPath);
      const anyHypOff = pathHyps.some(h => !activeAssumptions.has(h.id));

      // Also check if any direct supporter is dimmed
      const directSupporters = data.edges.filter(e =>
        e.to === concl.id &&
        e.relation !== 'contests' &&
        e.relation !== 'negates'
      );
      const anyDirectDimmed = directSupporters.some(e => dimmedNodes.has(e.from));

      if (anyHypOff || anyDirectDimmed) {
        // Some assumptions are off but conclusion isn't fully dimmed
        statusEl.textContent = anyHypOff ? 'Unsupported' : 'Contested';
        statusEl.className = anyHypOff
          ? 'conclusion-status status-unsupported'
          : 'conclusion-status status-contested';
      } else {
        statusEl.textContent = 'Supported';
        statusEl.className = 'conclusion-status status-supported';
      }
    });
  }

  function updateScenarioStatus() {
    const challengerEl = document.getElementById('scenario-challenger');
    const governmentEl = document.getElementById('scenario-government');
    if (!challengerEl || !governmentEl || !data) return;

    const conclusions = data.nodes.filter(n => n.type === 'FINAL_CONCLUSION');
    conclusions.forEach(concl => {
      const targetEl = concl.id === 'concl-challenger' ? challengerEl : governmentEl;

      if (dimmedNodes.has(concl.id)) {
        targetEl.textContent = 'Unsupported';
        targetEl.className = 'scenario-badge status-unsupported';
        return;
      }

      const conclPath = concl.path;
      const pathHyps = data.hypotheticals.filter(h => h.path === conclPath);
      const anyHypOff = pathHyps.some(h => !activeAssumptions.has(h.id));
      const directSupporters = data.edges.filter(e =>
        e.to === concl.id && e.relation !== 'contests' && e.relation !== 'negates'
      );
      const anyDirectDimmed = directSupporters.some(e => dimmedNodes.has(e.from));

      if (anyHypOff || anyDirectDimmed) {
        targetEl.textContent = anyHypOff ? 'Unsupported' : 'Contested';
        targetEl.className = anyHypOff
          ? 'scenario-badge status-unsupported'
          : 'scenario-badge status-contested';
      } else {
        targetEl.textContent = 'Supported';
        targetEl.className = 'scenario-badge status-supported';
      }
    });
  }

  // ---- Render Graph ----
  function renderGraph() {
    const container = document.getElementById('graph-container');
    container.innerHTML = '';

    const showChallenger = document.getElementById('filter-challenger').checked;
    const showGovernment = document.getElementById('filter-government').checked;
    const showNeutral = document.getElementById('filter-neutral').checked;
    const highlightAxiomFree = document.getElementById('filter-axiom-free').checked;
    const highlightHighRisk = document.getElementById('filter-high-risk').checked;

    data.layers.forEach(layer => {
      const layerNodes = data.nodes.filter(n => {
        if (n.layer !== layer.id) return false;
        // Path filtering
        const p = n.path || 'neutral';
        if (p === 'challenger' && !showChallenger) return false;
        if (p === 'government' && !showGovernment) return false;
        if (p === 'neutral' && !showNeutral) return false;
        if (p === 'traceability' && !showNeutral) return false;
        if (p === 'contested') return true; // always show contested
        return true;
      });

      if (layerNodes.length === 0) return;

      const layerEl = document.createElement('div');
      layerEl.className = `graph-layer layer-${layer.id}`;

      const titleEl = document.createElement('div');
      titleEl.className = 'graph-layer-title';
      titleEl.textContent = `${layer.order}. ${layer.label}`;
      layerEl.appendChild(titleEl);

      const nodesEl = document.createElement('div');
      nodesEl.className = 'graph-layer-nodes';

      layerNodes.forEach(node => {
        const nodeEl = createNodeElement(node, highlightAxiomFree, highlightHighRisk);
        nodesEl.appendChild(nodeEl);
      });

      layerEl.appendChild(nodesEl);
      container.appendChild(layerEl);
    });

    // Recalculate dimming and update states
    recalculateDimming();
    updateNodeStates();
  }

  function createNodeElement(node, highlightAxiomFree, highlightHighRisk) {
    const el = document.createElement('div');
    el.className = `graph-node type-${node.type}`;
    el.id = `node-${node.id}`;

    if (node.path === 'challenger') el.classList.add('path-challenger-node');
    if (node.path === 'government') el.classList.add('path-government-node');

    if (selectedNodeId === node.id) el.classList.add('selected');
    if (highlightAxiomFree && node.axiom_free) el.classList.add('highlighted');
    if (highlightHighRisk && node.high_risk) el.classList.add('highlighted');

    // Type color bar
    const bar = document.createElement('div');
    bar.className = 'node-type-bar';
    el.appendChild(bar);

    // Label
    const label = document.createElement('div');
    label.className = 'node-label';
    label.textContent = node.label;
    el.appendChild(label);

    // Badges
    const badges = document.createElement('div');
    badges.className = 'node-badges';

    if (node.axiom_free) {
      const b = document.createElement('span');
      b.className = 'node-badge badge-0-axioms';
      b.textContent = '0 Axioms';
      badges.appendChild(b);
    }

    if (node.high_risk) {
      const b = document.createElement('span');
      b.className = 'node-badge badge-high-risk';
      b.textContent = 'High Risk';
      badges.appendChild(b);
    }

    if (node.trusted_base && !node.high_risk) {
      const b = document.createElement('span');
      b.className = 'node-badge badge-trusted';
      b.textContent = 'Trusted Base';
      badges.appendChild(b);
    }

    if (node.type === 'THEOREM' && !node.axiom_free && node.axiom_count > 0) {
      const b = document.createElement('span');
      b.className = 'node-badge badge-depends';
      b.textContent = `${node.axiom_count} Axioms`;
      badges.appendChild(b);
    }

    if (badges.childNodes.length > 0) el.appendChild(badges);

    // Reviewer-mode detail line (hidden by default, shown via body.reviewer-active)
    if (node.acl2_event || node.book || node.axiom_count !== undefined) {
      const rev = document.createElement('div');
      rev.className = 'reviewer-detail';
      const parts = [];
      if (node.acl2_event) parts.push(`<span class="reviewer-tag">Event</span>${node.acl2_event}`);
      if (node.book) parts.push(`<span class="reviewer-tag">Book</span>${node.book.replace('.lisp', '')}`);
      if (node.axiom_count !== undefined) parts.push(`<span class="reviewer-tag">Axioms</span>${node.axiom_count}`);
      if (node.type) parts.push(`<span class="reviewer-tag">Type</span>${TYPE_LABELS[node.type] || node.type}`);
      rev.innerHTML = parts.join('<br>');
      el.appendChild(rev);
    }

    // Conclusion status badge
    if (node.type === 'FINAL_CONCLUSION') {
      const statusEl = document.createElement('div');
      statusEl.id = `status-${node.id}`;
      statusEl.className = 'conclusion-status status-supported';
      statusEl.textContent = 'Supported';
      el.appendChild(statusEl);
    }

    // Click handler
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      selectNode(node);
    });

    return el;
  }

  // ---- Node Selection & Detail Panel ----
  function selectNode(node) {
    // Deselect previous
    if (selectedNodeId) {
      const prev = document.getElementById(`node-${selectedNodeId}`);
      if (prev) prev.classList.remove('selected');
    }

    selectedNodeId = node.id;
    const el = document.getElementById(`node-${node.id}`);
    if (el) el.classList.add('selected');

    renderDetail(node);
  }

  function renderDetail(node) {
    const container = document.getElementById('detail-content');
    container.innerHTML = '';

    // Header
    const header = document.createElement('div');
    header.className = 'detail-header';
    header.textContent = node.label;
    container.appendChild(header);

    // Type badge
    const typeBadge = document.createElement('span');
    typeBadge.className = 'detail-type-badge';
    typeBadge.style.background = `${TYPE_COLORS[node.type]}22`;
    typeBadge.style.color = TYPE_COLORS[node.type];
    typeBadge.textContent = TYPE_LABELS[node.type] || node.type;
    container.appendChild(typeBadge);

    addDivider(container);

    // Why This Matters — curated plain-English callout
    if (node.why_it_matters) {
      const callout = document.createElement('div');
      callout.className = 'detail-why-matters';

      const calloutLabel = document.createElement('div');
      calloutLabel.className = 'detail-label';
      calloutLabel.textContent = 'Why This Matters';

      const calloutValue = document.createElement('div');
      calloutValue.className = 'detail-value';
      calloutValue.textContent = node.why_it_matters;

      callout.appendChild(calloutLabel);
      callout.appendChild(calloutValue);
      container.appendChild(callout);
    }

    // Description
    if (node.description) {
      addDetailBlock(container, 'Description', node.description);
    }

    // ACL2 Event
    if (node.acl2_event) {
      addDetailBlock(container, 'ACL2 Event', node.acl2_event, true);
    }

    // Book
    if (node.book) {
      addDetailBlock(container, 'ACL2 Book', node.book, true);
    }

    // Source Reference
    if (node.source_ref) {
      addDetailBlock(container, 'Source Reference', node.source_ref);
    }

    // ACE Text
    if (node.ace_text) {
      addDetailBlock(container, 'ACE Text', node.ace_text);
    }

    // Source Text
    if (node.source_text) {
      addDetailBlock(container, 'Source Text', node.source_text);
    }

    // Predicate Target
    if (node.predicate_target) {
      addDetailBlock(container, 'Predicate Target', node.predicate_target, true);
    }

    addDivider(container);

    // Path
    if (node.path) {
      addDetailBlock(container, 'Path', node.path);
    }

    // Axiom count
    if (node.axiom_count !== undefined) {
      addDetailBlock(container, 'Axiom Dependencies', node.axiom_count === 0 ? '0 (axiom-free structural proof)' : `${node.axiom_count} axioms`);
    }

    // Trusted base
    if (node.trusted_base !== undefined) {
      addDetailBlock(container, 'Trusted Base', node.trusted_base ? 'Yes — not proved by ACL2' : 'No');
    }

    // High risk
    if (node.high_risk) {
      addDetailBlock(container, 'Risk Level', 'HIGH — contestable, outcome-influencing');
    }

    addDivider(container);

    // Deep links to repo artifacts
    const repoUrl = data.meta.repo_url || 'https://github.com/f-pound/federal_save_act';
    const linksContainer = document.createElement('div');
    linksContainer.className = 'detail-links';
    let hasLinks = false;

    if (node.book) {
      addRepoLink(linksContainer, '📄', 'ACL2 Book', `${repoUrl}/blob/master/model/${node.book}`);
      hasLinks = true;
    }
    if (node.type === 'FINAL_CONCLUSION' || node.type === 'THEOREM') {
      addRepoLink(linksContainer, '🔗', 'Proof Dependencies', `${repoUrl}/blob/master/reports/proof_dependency_report.md`);
      hasLinks = true;
    }
    if (node.high_risk || node.type === 'EMPIRICAL_ASSUMPTION') {
      addRepoLink(linksContainer, '⚠', 'Axiom Pressure', `${repoUrl}/blob/master/reports/axiom_pressure_report.md`);
      hasLinks = true;
    }
    if (node.trusted_base || node.type === 'SCENARIO_FACT' || node.type === 'TEXT_FACT') {
      addRepoLink(linksContainer, '📋', 'Source Trace', `${repoUrl}/blob/master/reports/axiom_inventory.md`);
      hasLinks = true;
    }
    if (node.book) {
      addRepoLink(linksContainer, '✅', 'Certification', `${repoUrl}/blob/master/reports/certification_status.md`);
      hasLinks = true;
    }

    if (hasLinks) {
      const linksLabel = document.createElement('div');
      linksLabel.className = 'detail-label';
      linksLabel.textContent = 'Repository Artifacts';
      container.appendChild(linksLabel);
      container.appendChild(linksContainer);
      addDivider(container);
    }

    // Dependencies (incoming edges)
    const deps = data.edges.filter(e => e.to === node.id);
    if (deps.length > 0) {
      const depNames = deps.map(e => {
        const src = data.nodes.find(n => n.id === e.from);
        return src ? `${src.label} (${e.relation})` : `${e.from} (${e.relation})`;
      });
      addDetailBlock(container, 'Depends On', depNames.join('\n'));
    }

    // Supports (outgoing edges)
    const supports = data.edges.filter(e => e.from === node.id);
    if (supports.length > 0) {
      const supNames = supports.map(e => {
        const tgt = data.nodes.find(n => n.id === e.to);
        return tgt ? `${tgt.label} (${e.relation})` : `${e.to} (${e.relation})`;
      });
      addDetailBlock(container, 'Supports', supNames.join('\n'));
    }
  }

  function addRepoLink(container, icon, label, url) {
    const a = document.createElement('a');
    a.className = 'detail-link';
    a.href = url;
    a.target = '_blank';
    a.rel = 'noopener';
    a.innerHTML = `<span class="detail-link-icon">${icon}</span>${label}`;
    container.appendChild(a);
  }

  function addDetailBlock(container, label, value, mono) {
    const block = document.createElement('div');
    block.className = 'detail-block';

    const labelEl = document.createElement('div');
    labelEl.className = 'detail-label';
    labelEl.textContent = label;

    const valueEl = document.createElement('div');
    valueEl.className = `detail-value${mono ? ' mono' : ''}`;
    valueEl.textContent = value;

    block.appendChild(labelEl);
    block.appendChild(valueEl);
    container.appendChild(block);
  }

  function addDivider(container) {
    const div = document.createElement('div');
    div.className = 'detail-divider';
    container.appendChild(div);
  }

  // ---- Init on DOM ready ----
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
