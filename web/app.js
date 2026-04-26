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
