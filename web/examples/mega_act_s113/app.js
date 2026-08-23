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
      label: 'Both sides',
      description: 'Every premise from both parties is switched on. Both conditional conclusions are supported — the model is showing that each side\'s argument is internally valid, not which one wins.',
      hyps: ['hyp-no-fault', 'hyp-material-burden', 'hyp-burden-not-severe', 'hyp-adequate-alt',
             'hyp-mandatory', 'hyp-discretionary', 'hyp-election-integrity', 'hyp-reasonable', 'hyp-severe-defeats',
             'hyp-removal-due-process', 'hyp-removal-valid-maintenance',
             'hyp-voting-severe-burden', 'hyp-voting-material-burden', 'hyp-photo-id-valid',
             'hyp-poll-tax', 'hyp-document-cost', 'hyp-no-fee-waiver', 'hyp-fee-waiver'],
    },
    challenger: {
      label: "Challenger's case",
      description: 'Only the challenger\'s premises: citizens lack documents through no fault, obtaining them is a material burden, the alternative process is discretionary, and a severe burden defeats the regulation. The government\'s no-conflict conclusion loses its support.',
      hyps: ['hyp-no-fault', 'hyp-material-burden', 'hyp-discretionary', 'hyp-severe-defeats', 'hyp-removal-due-process',
             'hyp-voting-severe-burden', 'hyp-voting-material-burden', 'hyp-poll-tax', 'hyp-document-cost', 'hyp-no-fee-waiver'],
    },
    government: {
      label: "Government's defense",
      description: 'Only the government\'s premises: election integrity is an important interest, the requirement is reasonable and evenhanded, the burden is not severe, and the alternative process is adequate and mandatory. The challenger\'s conflict conclusion loses its support.',
      hyps: ['hyp-burden-not-severe', 'hyp-adequate-alt', 'hyp-mandatory',
             'hyp-election-integrity', 'hyp-reasonable', 'hyp-removal-valid-maintenance', 'hyp-photo-id-valid', 'hyp-fee-waiver'],
    },
    neutral: {
      label: 'Statute text only',
      description: 'No legal, empirical or interpretive premises — just the statute\'s text and the executable process model. Neither constitutional outcome is derivable; only the structural theorems (green "0 axioms") and the § 8(k) removal result remain.',
      hyps: [],
    },
    citizendocs: {
      label: 'Citizenship implies documents',
      description: 'Grants the challenger every LEGAL premise (fundamental right, discretionary reading, severe burden defeats regulation, removal due process) but denies the two EMPIRICAL ones: citizens can and do hold documents, and a waivable $15-35 fee is not a material burden. The challenger\'s registration conflict then rests on nothing; the government\'s no-conflict holds. Shows exactly which factual claim the registration dispute turns on.',
      hyps: ['hyp-burden-not-severe', 'hyp-adequate-alt', 'hyp-mandatory', 'hyp-discretionary',
             'hyp-election-integrity', 'hyp-reasonable', 'hyp-severe-defeats',
             'hyp-removal-due-process', 'hyp-removal-valid-maintenance',
             'hyp-voting-severe-burden', 'hyp-photo-id-valid', 'hyp-poll-tax', 'hyp-no-fee-waiver', 'hyp-fee-waiver'],
    },
    highrisk: {
      label: 'Contested premises only',
      description: 'Keeps only the three empirically contestable premises about burden severity and drops every doctrinal and interpretive one. Shows how little is settled by facts alone.',
      hyps: ['hyp-no-fault', 'hyp-material-burden', 'hyp-burden-not-severe', 'hyp-voting-material-burden', 'hyp-document-cost'],
    },
  };

  // ---- Decider display names (who makes the determination an axiom encodes) ----
  const DECIDER_LABELS = {
    'legislature': 'Legislature — statutory text',
    'court': 'Court — doctrine / statutory interpretation',
    'fact-finder': 'Fact-finder — empirical finding',
    'party-stipulation': 'Party stipulation — conceded by both sides (or arguendo)',
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
    LIBRARY: 'Generic Lemma Library',
    CLAUSE_IR: 'Clause IR (generated)',
    DUE_PROCESS_OVERLAY: 'Due-Process Overlay (not in statute)',
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
    LIBRARY: '#2ECC71',
    CLAUSE_IR: '#708090',
    DUE_PROCESS_OVERLAY: '#F39C12',
  };

  // ---- Boot ----
  async function init() {
    try {
      const resp = await fetch('data/explorer.json', { cache: 'no-store' });
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      data = await resp.json();
    } catch (err) {
      document.getElementById('graph-container').innerHTML =
        `<p style="color:#E74C3C;padding:40px;">Failed to load explorer data: ${err.message}<br>Run <code>python tools/build_explorer_data.py</code> first.</p>`;
      return;
    }

    // Initialize hypotheticals from their defaults BEFORE the first render,
    // otherwise conclusion statuses are computed with every assumption off.
    // (v6.0 fix: previously all cards showed "Unsupported" on load.)
    data.hypotheticals.forEach(h => { if (h.default !== false) activeAssumptions.add(h.id); });

    if (data.meta && data.meta.title) {
      const h = document.querySelector('.header-title h1'); if (h) h.textContent = data.meta.title.split(' — ')[0];
      document.title = data.meta.title;
    }
    renderAuditBar();
    renderControls();
    renderGraph();
    renderFooter();
    renderStatusBar();
    renderVoterDocs();
    renderPollDocs();
    setupMemo();
    setupTour();
    setupHinge();
    if (!readUrlState()) writeUrlState();
    renderDispute();
    if (!localStorage.getItem('explorer-toured') && localStorage.getItem('explorer-seen')) setTimeout(() => tourShow(0), 600);

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

    // Initial dimming, node/conclusion statuses and scenario status
    recalculateDimming();
    updateNodeStates();
    updateScenarioStatus();
  }

  // ---- Preset Buttons ----
  function adaptPresetsToProject() {
    const ids = new Set(data.hypotheticals.map(h => h.id));
    const known = PRESETS.compare.hyps.filter(id => ids.has(id));
    if (known.length) return;   // this project uses the curated presets
    const byPath = p => data.hypotheticals.filter(h => h.path === p).map(h => h.id);
    PRESETS.compare.hyps = data.hypotheticals.map(h => h.id);
    PRESETS.challenger.hyps = byPath('challenger');
    PRESETS.government.hyps = byPath('government');
    PRESETS.neutral.hyps = [];
    PRESETS.citizendocs.hyps = byPath('government').concat(byPath('challenger').filter(id => !/burden|fault/.test(id)));
    PRESETS.highrisk.hyps = data.hypotheticals.filter(h => /fact-finder|empirical/i.test(h.category)).map(h => h.id);
    PRESETS.compare.description = 'Every premise from both parties is switched on. Both conditional conclusions are supported — each side\'s argument is internally valid; the tool does not say which wins.';
    PRESETS.challenger.description = 'Only the challenger\'s premises (its reading of the statute and its doctrine). The government\'s conclusion loses its support.';
    PRESETS.government.description = 'Only the government\'s premises. The challenger\'s conclusion loses its support.';
    PRESETS.neutral.description = 'No legal or empirical premises — only the statute\'s text and the executable model. Neither conclusion is derivable; the structural theorems remain.';
    PRESETS.citizendocs.description = 'Every legal premise of both sides on; the challenger\'s empirical premises (burden / fault) off.';
    PRESETS.highrisk.description = 'Only the empirical (fact-finder) premises.';
    const cd = document.querySelector('[data-preset="citizendocs"]'); if (cd) cd.textContent = 'Legal premises only';
    // project-specific prose in the About modal and jump bar
    const lead = document.querySelector('.modal-lead');
    if (lead && data.meta && data.meta.project !== 'federal_save_act') {
      lead.innerHTML = `This is a <strong>Computational Amicus Explorer</strong> for <strong>${data.meta.title || data.meta.project}</strong>: a theorem prover (ACL2) has checked, from explicitly stated premises, what each side's argument proves. You choose the premises; the outcomes follow mechanically.`;
      document.querySelectorAll('.modal-section').forEach((sec, i) => { if (i === 0) sec.classList.add('hidden'); });
    }
    document.querySelectorAll('.jump-bar a[href="#voter-panel"], .jump-bar a[href="#poll-panel"]').forEach(a => a.classList.add('hidden'));
  }

  function setupPresets() {
    adaptPresetsToProject();
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
    writeUrlState(); renderDispute(); if (typeof renderHinge === 'function') renderHinge();
  }

  function updatePresetHighlight() {
    const desc = document.getElementById('preset-description');
    if (desc) {
      desc.textContent = activePreset && PRESETS[activePreset]
        ? PRESETS[activePreset].description
        : 'Custom selection — you have changed premises by hand. Pick a preset to reset.';
    }
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
  // ---- Voter cartoon: same tables, same rule, then the user's premises ----
  const DOC_LABELS = {
    'real-id-indicating-citizenship': 'REAL ID that indicates citizenship (enhanced licence, 5 states)',
    'valid-us-passport': 'U.S. passport',
    'military-id-with-us-birth': 'Military ID + service record showing U.S. birth',
    'govt-photo-id-showing-us-birth': 'Government photo ID showing U.S. birthplace',
    'govt-photo-id': 'Government photo ID (ordinary driver\'s licence / REAL ID)',
    'certified-birth-certificate': 'Certified birth certificate',
    'hospital-birth-record': 'Hospital record of birth',
    'final-adoption-decree': 'Final adoption decree showing U.S. birth',
    'consular-report-of-birth-abroad': 'Consular Report of Birth Abroad',
    'naturalization-certificate': 'Naturalization Certificate / Certificate of Citizenship',
    'american-indian-card-kic': 'American Indian Card (KIC)',
  };
  const CARD_LABELS = {
    'real-id-indicating-citizenship': 'ENH. ID', 'valid-us-passport': 'PASSPORT',
    'military-id-with-us-birth': 'MIL ID', 'govt-photo-id-showing-us-birth': 'PHOTO ID*',
    'govt-photo-id': 'PHOTO ID', 'certified-birth-certificate': 'BIRTH CERT',
    'hospital-birth-record': 'HOSP. REC', 'final-adoption-decree': 'ADOPTION',
    'consular-report-of-birth-abroad': 'CRBA', 'naturalization-certificate': 'NAT. CERT',
    'american-indian-card-kic': 'KIC CARD',
  };
  const MOUTHS = {
    smile: 'M134 101 q9 9 18 0', frown: 'M134 106 q9 -9 18 0', flat: 'M135 103 h16', unsure: 'M134 104 q4 -4 8 0 q4 4 8 0',
  };
  function setExpression(kind) {
    const m = document.getElementById('voter-mouth');
    const mark = document.getElementById('voter-mark');
    const clerk = document.getElementById('clerk-mouth');
    if (m) m.setAttribute('d', MOUTHS[kind] || MOUTHS.flat);
    if (mark) mark.setAttribute('opacity', kind === 'unsure' ? '1' : '0');
    if (clerk) clerk.setAttribute('d', kind === 'smile' ? 'M410 110 q8 7 16 0' : kind === 'frown' ? 'M410 113 q8 -5 16 0' : 'M410 111 h16');
  }

  const GROUP_LABELS = {
    'standalone-proof-types': 'Counts on its own — § 3(b)(1)-(4)',
    'anchor-photo-id-types': 'Counts only when paired with a supporting document — § 3(b)(5)',
    'supporting-document-types': 'Supporting document — counts only together with the photo ID above — § 3(b)(5)(A)-(F)',
  };
  const voterDocs = new Set();

  function renderVoterDocs() {
    const cats = data.meta && data.meta.document_categories;
    const host = document.getElementById('voter-doc-groups');
    if (!cats || !host) { const p = document.getElementById('voter-panel'); if (p) p.classList.add('hidden'); return; }
    let html = '';
    for (const [cat, members] of Object.entries(cats)) {
      html += `<div class="voter-group"><div class="voter-group-name">${GROUP_LABELS[cat] || cat}</div>`;
      members.forEach(m => {
        html += `<label class="voter-doc" title="${(m.text || '').replace(/"/g, '')}"><input type="checkbox" data-doc="${m.symbol}"> ${DOC_LABELS[m.symbol] || m.symbol} <span class="who">${m.source}</span></label>`;
      });
      html += '</div>';
    }
    host.innerHTML = html;
    host.querySelectorAll('input[data-doc]').forEach(cb => cb.addEventListener('change', () => {
      if (cb.checked) voterDocs.add(cb.dataset.doc); else voterDocs.delete(cb.dataset.doc);
      renderVoterOutcome();
    }));
    document.getElementById('voter-attest').addEventListener('change', renderVoterOutcome);
    document.getElementById('voter-citizen').addEventListener('change', renderVoterOutcome);
    renderVoterOutcome();
  }

  // Mirror of the generated documentary-proof-bundlep:
  //   some standalone  OR  (some anchor AND some supporting)
  function documentaryProofBundle(docs, cats) {
    const some = c => (cats[c] || []).some(m => docs.has(m.symbol));
    return some('standalone-proof-types') ||
           (some('anchor-photo-id-types') && some('supporting-document-types'));
  }

  function conclusionStatus(id) {
    const el = document.getElementById(`status-${id}`);
    return el ? el.textContent : '—';
  }

  function renderVoterOutcome() {
    const cats = data.meta && data.meta.document_categories;
    if (!cats) return;
    const attest = document.getElementById('voter-attest').checked;
    const citizen = document.getElementById('voter-citizen').checked;
    const proof = documentaryProofBundle(voterDocs, cats);
    const mandatory = activeAssumptions.has('hyp-mandatory');
    const discretionary = activeAssumptions.has('hyp-discretionary');

    // cards fanned in the applicant's hand, over the counter
    const cards = document.getElementById('voter-cards');
    const list = [...voterDocs];
    let ch = '';
    list.forEach((d, i) => {
      const n = list.length;
      const angle = -18 + (n === 1 ? 18 : (36 * i) / (n - 1));
      const dx = 6 + i * (n > 4 ? 9 : 14);
      ch += `<g transform="translate(${dx},${-34}) rotate(${angle} 0 34)">` +
            `<rect width="46" height="30" rx="3" fill="#fdfdfd" stroke="#8a93a3" stroke-width="1"/>` +
            `<rect x="4" y="5" width="12" height="12" rx="2" fill="#cfd6e2"/>` +
            `<rect x="19" y="7" width="22" height="2.5" fill="#b7c0cf"/><rect x="19" y="12" width="16" height="2.5" fill="#b7c0cf"/>` +
            `<text class="voter-card" x="23" y="25" text-anchor="middle" fill="#333">${CARD_LABELS[d] || d}</text></g>`;
    });
    if (!list.length) ch = '<text x="-4" y="-6" font-size="10" font-style="italic" fill="#9aa7b4" font-family="Inter, sans-serif">empty-handed</text>';
    cards.innerHTML = ch;

    const steps = [];
    let bubble, face = 'flat';
    if (proof) {
      bubble = 'Documentary proof presented — application accepted and processed (§ 4(b)).';
      face = 'smile';
      steps.push(`<span class="step"><b class="ok">Registered.</b> The bundle satisfies § 3(b) (${[...voterDocs].join(', ')}). <span class="who">Who decides: legislature (statutory text) — no premise needed.</span></span>`);
      steps.push(`<span class="step">Neither constitutional conflict condition applies to this applicant: the statute does not deny registration.</span>`);
    } else if (!attest) {
      bubble = 'No documentary proof of citizenship presented — the State may not accept and process this application (§ 4(b), § 8(j)(1)).';
      face = 'frown';
      steps.push(`<span class="step"><b class="bad">Denied.</b> Nothing presented is in the § 3(b) table${voterDocs.size ? ' (a supporting document without a photo ID, or a plain REAL ID, does not count)' : ''}, and the alternative process was not invoked. <span class="who">Who decides: legislature.</span></span>`);
    } else if (mandatory && !discretionary) {
      bubble = 'Attestation and other evidence received — citizenship sufficiently established; I must register you (mandatory reading of § 8(j)(2)(A)).';
      face = 'smile';
      steps.push(`<span class="step"><b class="ok">Registered through the alternative process.</b> <span class="who">Who decides: court — you have the MANDATORY reading switched on.</span></span>`);
    } else if (discretionary && !mandatory) {
      bubble = '"I shall make a determination"… I am not satisfied. Denied (discretionary reading of § 8(j)(2)(A)).';
      face = 'frown';
      steps.push(`<span class="step"><b class="mid">Denial possible.</b> Under the DISCRETIONARY reading the official may find citizenship not sufficiently established. <span class="who">Who decides: court (interpretation of "shall make a determination").</span></span>`);
    } else if (mandatory && discretionary) {
      bubble = 'Depends on how a court reads § 8(j)(2)(A): "shall make a determination" — must I register you, or may I decide?';
      face = 'unsure';
      steps.push(`<span class="step"><b class="mid">Unresolved hinge.</b> Both readings are switched on; the model treats them as separate paths. Turn one off to see the outcome. <span class="who">Who decides: court.</span></span>`);
    } else {
      bubble = 'Attestation received, but no reading of § 8(j)(2)(A) is in force — no outcome can be derived.';
      face = 'unsure';
      steps.push(`<span class="step"><b class="mid">No hinge premise on.</b> Switch on the mandatory or the discretionary reading.</span>`);
    }

    const denied = !proof && (!attest || (discretionary && !mandatory));
    if (denied) {
      if (!citizen) {
        steps.push(`<span class="step">The applicant is not a citizen, so no protected right to vote is engaged: <b>no constitutional conflict on either model</b> — the statute did what it says.</span>`);
      } else {
        const c = conclusionStatus('concl-challenger'), g = conclusionStatus('concl-government');
        steps.push(`<span class="step">A qualified <b>citizen</b> has been denied. What that means depends on your premises:</span>`);
        steps.push(`<span class="step">• Challenger — constitutional conflict: <b class="${c === 'Supported' ? 'bad' : 'mid'}">${c}</b> <span class="who">(needs: no-fault, material burden, severe burden defeats — fact-finder + court)</span></span>`);
        steps.push(`<span class="step">• Government — valid regulation, no conflict: <b class="${g === 'Supported' ? 'ok' : 'mid'}">${g}</b> <span class="who">(needs: important interest, evenhanded, burden not severe, adequate alternative — court + fact-finder)</span></span>`);
      }
    }
    document.getElementById('voter-bubble-text').textContent = bubble;
    setExpression(face);
    document.getElementById('voter-outcome').innerHTML = steps.join('');
  }

  // ---- Election-day scene: § 303A valid photo ID, provisional cure, premises ----
  const POLL_LABELS = {
    'state-drivers-license-with-expiration': 'State driver\'s licence with photo AND expiration date',
    'state-id-card-with-expiration': 'State DMV ID card with photo AND expiration date',
    'valid-us-passport': 'U.S. passport',
    'valid-military-identification': 'Military identification',
    'tribal-id-with-expiration': 'Tribal ID with photo AND expiration date',
    'religious-objection-affidavit': 'Religious-objection affidavit (cure only, not photo ID)',
  };
  const POLL_CARDS = {
    'state-drivers-license-with-expiration': 'DRIVER LIC', 'state-id-card-with-expiration': 'STATE ID',
    'valid-us-passport': 'PASSPORT', 'valid-military-identification': 'MIL ID',
    'tribal-id-with-expiration': 'TRIBAL ID', 'religious-objection-affidavit': 'AFFIDAVIT',
  };
  const POLL_GROUPS = {
    'valid-photo-id-types': 'Valid photo identification — § 303A(c)(1)-(5)',
    'religious-objection-affidavit-types': 'Cure only — § 303A(a)(1)(B)(i)(II)',
  };
  const pollDocs = new Set();

  function renderPollDocs() {
    const cats = data.meta && data.meta.voting_categories;
    const host = document.getElementById('poll-doc-groups');
    if (!cats || !host) { const p = document.getElementById('poll-panel'); if (p) p.classList.add('hidden'); return; }
    let html = '';
    for (const [cat, members] of Object.entries(cats)) {
      html += `<div class="voter-group"><div class="voter-group-name">${POLL_GROUPS[cat] || cat}</div>`;
      members.forEach(m => {
        html += `<label class="voter-doc" title="${(m.text || '').replace(/"/g, '')}"><input type="checkbox" data-poll="${m.symbol}"> ${POLL_LABELS[m.symbol] || m.symbol} <span class="who">${m.source}</span></label>`;
      });
      html += '</div>';
    }
    host.innerHTML = html;
    host.querySelectorAll('input[data-poll]').forEach(cb => cb.addEventListener('change', () => {
      if (cb.checked) pollDocs.add(cb.dataset.poll); else pollDocs.delete(cb.dataset.poll);
      renderPollOutcome();
    }));
    document.getElementById('poll-cure').addEventListener('change', renderPollOutcome);
    document.getElementById('poll-citizen').addEventListener('change', renderPollOutcome);
    renderPollOutcome();
  }

  function setPollExpression(kind) {
    const m = document.getElementById('poll-mouth');
    const mark = document.getElementById('poll-mark');
    const w = document.getElementById('poll-worker-mouth');
    if (m) m.setAttribute('d', MOUTHS[kind] || MOUTHS.flat);
    if (mark) mark.setAttribute('opacity', kind === 'unsure' ? '1' : '0');
    if (w) w.setAttribute('d', kind === 'smile' ? 'M380 110 q8 7 16 0' : kind === 'frown' ? 'M380 113 q8 -5 16 0' : 'M380 111 h16');
  }

  function renderPollOutcome() {
    const cats = data.meta && data.meta.voting_categories;
    if (!cats) return;
    const some = c => (cats[c] || []).some(m => pollDocs.has(m.symbol));
    const photoId = some('valid-photo-id-types');                       // valid-photo-identification-bundlep
    const cureDocs = photoId || some('religious-objection-affidavit-types'); // provisional-cure-bundlep
    const cure = document.getElementById('poll-cure').checked;
    const citizen = document.getElementById('poll-citizen').checked;

    const cards = document.getElementById('poll-cards');
    const list = [...pollDocs];
    let ch = '';
    list.forEach((d, i) => {
      const n = list.length, angle = -18 + (n === 1 ? 18 : (36 * i) / (n - 1)), dx = 6 + i * (n > 4 ? 9 : 14);
      ch += `<g transform="translate(${dx},-34) rotate(${angle} 0 34)"><rect width="46" height="30" rx="3" fill="#fdfdfd" stroke="#8a93a3"/><rect x="4" y="5" width="12" height="12" rx="2" fill="#cfd6e2"/><rect x="19" y="7" width="22" height="2.5" fill="#b7c0cf"/><rect x="19" y="12" width="16" height="2.5" fill="#b7c0cf"/><text class="voter-card" x="23" y="25" text-anchor="middle" fill="#333">${POLL_CARDS[d] || d}</text></g>`;
    });
    if (!list.length) ch = '<text x="-4" y="-6" font-size="10" font-style="italic" fill="#9aa7b4" font-family="Inter, sans-serif">empty-handed</text>';
    cards.innerHTML = ch;

    const ballot = document.getElementById('poll-ballot');
    const ballotSub = document.getElementById('poll-ballot-sub');
    const steps = [];
    let bubble, face;
    if (photoId) {
      bubble = 'Valid photo identification — here is your regular ballot (§ 303A(a)(1)(A)).';
      face = 'smile';
      ballot.setAttribute('opacity', '1'); ballotSub.textContent = 'COUNTED'; ballotSub.setAttribute('fill', '#2ecc71');
      steps.push(`<span class="step"><b class="ok">Regular ballot, counted.</b> The bundle satisfies § 303A(c). <span class="who">Who decides: legislature — no premise needed.</span></span>`);
      steps.push(`<span class="step">No voting conflict condition applies: the ballot was counted.</span>`);
    } else {
      bubble = 'No valid photo ID — you may cast a provisional ballot. Come back within 3 days with ID or a religious-objection affidavit, or it will not count (§ 303A(a)(1)(B)).';
      const cured = cure || (pollDocs.has('religious-objection-affidavit'));
      if (cured) {
        face = 'smile';
        ballot.setAttribute('opacity', '1'); ballotSub.textContent = 'COUNTED'; ballotSub.setAttribute('fill', '#2ecc71');
        steps.push(`<span class="step"><b class="ok">Provisional ballot cured and counted.</b> ${pollDocs.has('religious-objection-affidavit') ? 'The religious-objection affidavit is the statute\'s one non-ID cure.' : 'ID presented within 3 days.'} <span class="who">Who decides: legislature.</span></span>`);
        steps.push(`<span class="step">A cured ballot is never a conflict (<span class="mono">core-cure-defeats-voting-conflict</span>).</span>`);
      } else {
        face = 'frown';
        ballot.setAttribute('opacity', '1'); ballotSub.textContent = 'REJECTED'; ballotSub.setAttribute('fill', '#e74c3c');
        steps.push(`<span class="step"><b class="bad">Provisional ballot rejected.</b> The 3-day window lapsed without cure — <span class="mono">no-id-and-lapse-rejects</span>. <span class="who">Who decides: legislature.</span></span>`);
        if (!citizen) {
          steps.push(`<span class="step">Not a registered citizen — no protected right engaged; <b>no conflict on either model</b>.</span>`);
        } else {
          const c = conclusionStatus('concl-challenger-voting'), g = conclusionStatus('concl-government-voting');
          steps.push(`<span class="step">A registered <b>citizen's</b> ballot went uncounted. What that means depends on your premises:</span>`);
          steps.push(`<span class="step">• Challenger — voting conflict: <b class="${c === 'Supported' ? 'bad' : 'mid'}">${c}</b> <span class="who">(needs: severe as-applied burden [court], cannot obtain ID without material burden [fact-finder])</span></span>`);
          steps.push(`<span class="step">• Government — valid regulation (Crawford), no conflict: <b class="${g === 'Supported' ? 'ok' : 'mid'}">${g}</b> <span class="who">(needs: important interest, evenhanded, adequate 3-day cure [court])</span></span>`);
        }
      }
    }
    document.getElementById('poll-bubble-text').textContent = bubble;
    setPollExpression(face);
    document.getElementById('poll-outcome').innerHTML = steps.join('');
  }

  // ---- Export memo: the current premise selection as a Markdown brief ----
  function axiomLookup() {
    const ad = data.audit_details;
    const map = {};
    if (ad && ad.axioms_by_book) Object.entries(ad.axioms_by_book).forEach(([book, arr]) => arr.forEach(a => { map[a.name] = { ...a, book }; }));
    return map;
  }

  function buildMemo() {
    const st = data.meta && data.meta.legislative_status;
    const ax = axiomLookup();
    const lines = [];
    lines.push('# Computational amicus memo — Federal SAVE Act (H.R. 22 / S. 1383)');
    lines.push('');
    lines.push(`_Generated from the Computational Amicus Explorer, v${data.meta.version || ''}. ${data.meta.books_certified || ''} ACL2 books certified, ${data.meta.theorems || ''} theorems Q.E.D., ${data.meta.axioms || ''} traced axioms. Preset: **${activePreset && PRESETS[activePreset] ? PRESETS[activePreset].label : 'custom'}**._`);
    if (st) lines.push(`_Legislative status (${st.as_of}): ${st.headline}_`);
    lines.push('');
    lines.push('## 1. What is proved unconditionally (no legal premise)');
    lines.push('');
    data.nodes.filter(n => n.axiom_free && (n.type === 'THEOREM' || n.type === 'LEMMA')).forEach(n => {
      lines.push(`- ${n.label}  \n  _ACL2:_ \`${n.acl2_event || n.id}\` (${n.book || ''})`);
    });
    lines.push('');
    lines.push('## 2. Premises selected (each is a choice; the tag says whose)');
    lines.push('');
    const groups = {};
    data.hypotheticals.forEach(h => { (groups[h.category] = groups[h.category] || []).push(h); });
    for (const [cat, hs] of Object.entries(groups)) {
      lines.push(`### ${cat}`);
      hs.forEach(h => {
        const on = activeAssumptions.has(h.id);
        const ctrl = h.controls.map(id => data.nodes.find(n => n.id === id)).filter(Boolean);
        const events = ctrl.flatMap(n => String(n.acl2_event || '').split(/,\s*/)).filter(e => ax[e]);
        const deciders = [...new Set(events.map(e => ax[e].decider).filter(Boolean))];
        const sources = [...new Set(ctrl.map(n => n.source_ref).filter(Boolean))];
        lines.push(`- [${on ? 'x' : ' '}] **${h.label}** (${h.path})` +
          (deciders.length ? ` — decided by: ${deciders.map(d => DECIDER_LABELS[d] || d).join('; ')}` : '') +
          (sources.length ? `  \n  _Source:_ ${sources.join('; ')}` : '') +
          (events.length ? `  \n  _Axioms:_ ${events.map(e => '\`' + e + '\`').join(', ')}` : ''));
      });
      lines.push('');
    }
    lines.push('## 3. Conditional conclusions under these premises');
    lines.push('');
    data.nodes.filter(n => n.type === 'FINAL_CONCLUSION').forEach(n => {
      const status = conclusionStatus(n.id);
      lines.push(`- **${n.label}** — ${status.toUpperCase()}  \n  ${n.description || ''}  \n  _Book:_ ${n.book || ''}`);
    });
    lines.push('');
    lines.push('## 4. Reading this memo');
    lines.push('');
    lines.push('ACL2 proved every "then"; the reader decides every "if". A conclusion marked SUPPORTED means: if the ticked premises hold, the conclusion follows as a theorem. UNSUPPORTED means a premise the proof needs is unticked — not that the conclusion is false. The model does not decide constitutionality; it makes the pivot explicit: `constitutional-conflict-conditionp` is equivalent to `(not (valid-regulationp law x))` once the other preconditions hold.');
    lines.push('');
    lines.push(`Reproduce this exact configuration: ${location.href}`);
    lines.push('');
    lines.push('Repository: https://github.com/f-pound/federal_save_act — sources/clause_trace.csv traces every axiom to its legal source and decider; tools/check_text_stability.py verifies every quoted clause verbatim in both bill texts.');
    return lines.join('\n');
  }

  function setupMemo() {
    const btn = document.getElementById('export-memo-btn');
    const modal = document.getElementById('memo-modal');
    if (!btn || !modal) return;
    const close = () => modal.classList.add('hidden');
    btn.addEventListener('click', () => {
      document.getElementById('memo-text').value = buildMemo();
      document.getElementById('memo-copied').textContent = '';
      modal.classList.remove('hidden');
    });
    document.getElementById('memo-close').addEventListener('click', close);
    modal.addEventListener('click', e => { if (e.target === modal) close(); });
    document.getElementById('memo-copy').addEventListener('click', async () => {
      const t = document.getElementById('memo-text');
      try { await navigator.clipboard.writeText(t.value); document.getElementById('memo-copied').textContent = 'Copied.'; }
      catch (e) { t.select(); document.execCommand('copy'); document.getElementById('memo-copied').textContent = 'Copied.'; }
    });
    const jc = document.getElementById('jump-conclusions');
    if (jc) jc.addEventListener('click', e => { e.preventDefault(); const p = document.querySelector('.panel-center'); p.scrollTop = p.scrollHeight; });
  }

  function renderStatusBar() {
    const st = data.meta && data.meta.legislative_status;
    const bar = document.getElementById('status-bar');
    if (!st || !bar) return;
    document.getElementById('status-text').textContent =
      `${st.headline} (as of ${st.as_of})`;
    const link = document.getElementById('status-link');
    link.href = 'https://github.com/f-pound/federal_save_act/blob/master/data/legislative_status.json';
    bar.classList.remove('hidden');
  }

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

  function deciderChip(d) {
    if (!d) return '';
    return `<span class="decider-chip decider-${d}" title="${(DECIDER_LABELS[d] || d).replace(/"/g, '')}">${d}</span>`;
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
    // Who decides — every axiom is a choice; this is whose.
    const deciderCounts = {};
    Object.values(ad.axioms_by_book).forEach(arr => arr.forEach(ax => {
      const d = ax.decider || 'untagged';
      deciderCounts[d] = (deciderCounts[d] || 0) + 1;
    }));
    html += '<div class="drawer-summary drawer-deciders"><span class="drawer-summary-label">Who decides:</span>';
    for (const [d, cnt] of Object.entries(deciderCounts)) {
      html += `<span class="decider-chip decider-${d}" title="${(DECIDER_LABELS[d] || d).replace(/"/g, '')}">${cnt} ${d}</span>`;
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
        html += deciderChip(ax.decider);
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
        cb.checked = h.default !== false;
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
  // ---- Shareable state: premises live in the URL hash (#p=<preset>&on=<ids>) ----
  function writeUrlState() {
    const on = [...activeAssumptions].map(id => id.replace(/^hyp-/, '')).join(',');
    const h = activePreset ? `p=${activePreset}` : `on=${on}`;
    if (history.replaceState) history.replaceState(null, '', '#' + h);
    const el = document.getElementById('share-link'); if (el) el.value = location.href;
  }
  function readUrlState() {
    const m = location.hash.slice(1);
    if (!m) return false;
    const q = Object.fromEntries(m.split('&').map(kv => kv.split('=')));
    if (q.p && PRESETS[q.p]) { applyPreset(q.p); return true; }
    if (q.on !== undefined) {
      activeAssumptions.clear();
      q.on.split(',').filter(Boolean).forEach(id => activeAssumptions.add('hyp-' + id));
      data.hypotheticals.forEach(h => { const cb = document.getElementById(`hyp-${h.id}`); if (cb) cb.checked = activeAssumptions.has(h.id); });
      activePreset = null; checkMutualExclusion(); recalculateDimming(); updateNodeStates(); updatePresetHighlight(); updateScenarioStatus();
      return true;
    }
    return false;
  }

  // ---- Dispute panel: what the two sides share and what they contest ----
  function renderDispute() {
    const host = document.getElementById('dispute-list'); if (!host) return;
    const byPath = p => data.hypotheticals.filter(h => h.path === p);
    const shared = data.nodes.filter(n => n.trusted_base && n.path === 'neutral' && n.layer === 'formalization');
    const rows = [];
    rows.push(`<div class="dispute-h">Common ground (${shared.length} premises both sides accept)</div>`);
    rows.push('<ul class="dispute-ul">' + shared.slice(0, 8).map(n => `<li>${n.label}</li>`).join('') + (shared.length > 8 ? `<li>… and ${shared.length - 8} more</li>` : '') + '</ul>');
    for (const p of ['challenger', 'government']) {
      rows.push(`<div class="dispute-h dispute-${p}">${p === 'challenger' ? 'Challenger needs' : 'Government needs'} (${byPath(p).length})</div>`);
      rows.push('<ul class="dispute-ul">' + byPath(p).map(h => `<li class="${activeAssumptions.has(h.id) ? '' : 'off'}">${h.label}<span class="who"> — ${h.category.replace(/.*—\s*/, '').replace(/ Assumptions$/, '')}</span></li>`).join('') + '</ul>');
    }
    host.innerHTML = rows.join('');
  }

  // ---- The hinge spotlight ----
  function setHinge(reading) {
    const want = { mandatory: ['hyp-mandatory'], discretionary: ['hyp-discretionary'], both: ['hyp-mandatory', 'hyp-discretionary'] }[reading] || [];
    ['hyp-mandatory', 'hyp-discretionary'].forEach(id => {
      const on = want.includes(id);
      if (on) activeAssumptions.add(id); else activeAssumptions.delete(id);
      const cb = document.getElementById(`hyp-${id}`); if (cb) cb.checked = on;
    });
    activePreset = null; updatePresetHighlight(); checkMutualExclusion(); recalculateDimming(); updateNodeStates(); updateScenarioStatus(); writeUrlState(); renderDispute();
    renderHinge();
  }
  function renderHinge() {
    const panel = document.getElementById('hinge-panel'); if (!panel) return;
    const hasHinge = data.hypotheticals.some(h => h.id === 'hyp-mandatory') && data.hypotheticals.some(h => h.id === 'hyp-discretionary');
    if (!hasHinge) { panel.classList.add('hidden'); return; }
    const m = activeAssumptions.has('hyp-mandatory'), d = activeAssumptions.has('hyp-discretionary');
    const reading = m && d ? 'both' : m ? 'mandatory' : d ? 'discretionary' : 'none';
    document.querySelectorAll('.hinge-btn').forEach(b => b.classList.toggle('active', b.dataset.reading === reading));
    const c = conclusionStatus('concl-challenger'), g = conclusionStatus('concl-government');
    let text;
    if (reading === 'mandatory') text = `<b>Under Reading A</b>, an applicant who attests and submits evidence is approved, so the denial trigger cannot fire through this path (<span class="mono">hinge-mandatory-no-denial-trigger</span>). The government’s no-conflict conclusion reads <b class="${g === 'Supported' ? 'ok' : 'mid'}">${g}</b>; the challenger’s conflict reads <b class="${c === 'Supported' ? 'bad' : 'mid'}">${c}</b> under your other premises.`;
    else if (reading === 'discretionary') text = `<b>Under Reading B</b>, a qualified citizen who attests and submits evidence can still be denied (<span class="mono">hinge-discretionary-qualified-voter-can-be-denied</span>), so the statute denies registration and the constitutional question is live. Challenger conflict: <b class="${c === 'Supported' ? 'bad' : 'mid'}">${c}</b>; government no-conflict: <b class="${g === 'Supported' ? 'ok' : 'mid'}">${g}</b>.`;
    else if (reading === 'both') text = `<b>Both readings on</b>: the model keeps them as separate conditional paths and proves each side’s conclusion on its own path. Pick one to see what a court’s choice does.`;
    else text = `<b>No reading selected</b>: neither the mandatory nor the discretionary consequence can be derived.`;
    document.getElementById('hinge-consequence').innerHTML = text;
    const aa = data.meta && data.meta.adversarial_audit;
    const cA = aa && aa['challenger-scenario-alternative-process-denied'], gA = aa && aa['government-scenario-alternative-process-approved'];
    const sm = (data.meta && data.meta.adversarial_summary) || {};
    const nC = (sm.challenger || {}).total || 0, nG = (sm.government || {}).total || 0;
    const indC = (sm.challenger || {}).independent || 0, indG = (sm.government || {}).independent || 0;
    document.getElementById('hinge-evidence-text').innerHTML = aa ? `The adversarial audit denied every premise in turn. Of the challenger’s ${nC} premises, ${indC} can be denied without disturbing any other; of the government’s ${nG}, ${indG}. The <b>only</b> coupled premise on each side is the alternative-process fact for citizen-a — locked to this reading: ` +
      (cA ? `<span class="mono">challenger-scenario-alternative-process-denied ⇄ ${cA.breaks.join(', ')}</span>` : '') + (gA ? ` and <span class="mono">government-scenario-alternative-process-approved ⇄ ${gA.breaks.join(', ')}</span>` : '') +
      `. No premise is provable from the others. Every other premise — burden, doctrine, bridges, the facts about citizen-a — is independent. <a href="https://github.com/f-pound/federal_save_act/blob/master/docs/AUDITS.md">How the audit works</a>.` : 'Audit data not available in this build.';
  }
  let spotlightTimer = null;
  function spotlight(on, ms) {
    document.body.classList.toggle('spotlight-on', on);
    if (spotlightTimer) { clearTimeout(spotlightTimer); spotlightTimer = null; }
    if (on && ms) spotlightTimer = setTimeout(() => document.body.classList.remove('spotlight-on'), ms);
  }
  function setupHinge() {
    document.querySelectorAll('.hinge-btn').forEach(b => b.addEventListener('click', () => setHinge(b.dataset.reading)));
    const sb = document.getElementById('spotlight-btn');
    if (sb) sb.addEventListener('click', () => {
      const on = !document.body.classList.contains('spotlight-on');
      if (on) document.getElementById('hinge-panel').scrollIntoView({ block: 'center', behavior: 'smooth' });
      spotlight(on, 0);
    });
    document.addEventListener('keydown', e => { if (e.key === 'Escape') spotlight(false, 0); });
    document.addEventListener('click', e => { if (document.body.classList.contains('spotlight-on') && !e.target.closest('#hinge-panel')) spotlight(false, 0); }, true);
    renderHinge();
    // first visit: light the hinge for a few seconds once the intro is dismissed
    if (!localStorage.getItem('hinge-spotlit')) {
      const fire = () => { localStorage.setItem('hinge-spotlit', '1'); document.getElementById('hinge-panel').scrollIntoView({ block: 'center' }); spotlight(true, 4500); };
      const modal = document.getElementById('about-modal');
      if (modal && !modal.classList.contains('hidden')) {
        ['modal-close', 'modal-got-it'].forEach(id => { const el = document.getElementById(id); if (el) el.addEventListener('click', () => setTimeout(fire, 300), { once: true }); });
      } else setTimeout(fire, 600);
    }
  }

  // ---- Guided tour ----
  const TOUR = [
    ['#hinge-panel', 'Start with the hinge: one statutory phrase, two readings. The audit proved it is the only premise in either theory that cannot move alone.'],
    ['#preset-bar', 'Start here. Each button is a complete, valid argument. Pick one — the description below it says which factual claim it rests on.'],
    ['#scenario-status', 'The outcome under the chosen premises. Supported means: if these premises hold, the conclusion follows as a theorem. Unsupported means a premise the proof needs is off — not that the conclusion is false.'],
    ['#controls-container', 'Every premise is a choice, and each one says whose: legislature, court, fact-finder, or a stipulation both sides accept. Untick one you doubt and watch what depended on it dim.'],
    ['#dispute-panel', 'The whole dispute in one list: what both sides accept, and what each side needs that the other does not.'],
    ['#export-memo-btn', 'When you have the configuration you want, export it: a memo listing the premises, their sources and deciders, and the conditional conclusions — with a link that reproduces this exact view.'],
  ];
  let tourStep = -1;
  function tourShow(i) {
    document.querySelectorAll('.tour-target').forEach(e => e.classList.remove('tour-target'));
    const tip = document.getElementById('tour-tip');
    if (i < 0 || i >= TOUR.length) { tip.classList.add('hidden'); tourStep = -1; localStorage.setItem('explorer-toured', '1'); return; }
    tourStep = i;
    const [sel, text] = TOUR[i];
    const el = document.querySelector(sel);
    if (el) { el.classList.add('tour-target'); el.scrollIntoView({ block: 'center', behavior: 'smooth' }); }
    document.getElementById('tour-text').textContent = text;
    document.getElementById('tour-count').textContent = `${i + 1} / ${TOUR.length}`;
    document.getElementById('tour-next').textContent = i === TOUR.length - 1 ? 'Done' : 'Next';
    tip.classList.remove('hidden');
  }
  function setupTour() {
    const btn = document.getElementById('tour-btn'); if (!btn) return;
    btn.addEventListener('click', () => tourShow(0));
    document.getElementById('tour-next').addEventListener('click', () => tourShow(tourStep + 1));
    document.getElementById('tour-skip').addEventListener('click', () => tourShow(-1));
  }

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
    writeUrlState(); renderDispute(); if (typeof renderHinge === 'function') renderHinge();
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
    if (typeof renderVoterOutcome === 'function' && data.meta && data.meta.document_categories) renderVoterOutcome();
    if (typeof renderPollOutcome === 'function' && data.meta && data.meta.voting_categories) renderPollOutcome();
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
      // Neutral (structural) conclusions are governed purely by dependency
      // dimming; the path-hypothetical heuristic applies to party conclusions.
      const pathHyps = (conclPath === 'neutral' || !conclPath) ? [] : data.hypotheticals.filter(h => h.path === conclPath);
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

    const badgeFor = { 'concl-challenger': challengerEl, 'concl-government': governmentEl };
    const conclusions = data.nodes.filter(n => n.type === 'FINAL_CONCLUSION' && badgeFor[n.id]);
    conclusions.forEach(concl => {
      const targetEl = badgeFor[concl.id];

      if (dimmedNodes.has(concl.id)) {
        targetEl.textContent = 'Unsupported';
        targetEl.className = 'scenario-badge status-unsupported';
        return;
      }

      const conclPath = concl.path;
      // Neutral (structural) conclusions are governed purely by dependency
      // dimming; the path-hypothetical heuristic applies to party conclusions.
      const pathHyps = (conclPath === 'neutral' || !conclPath) ? [] : data.hypotheticals.filter(h => h.path === conclPath);
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
    // Who decides?  Logic has no grey areas; every axiom is a CHOICE and
    // the trace CSV records whose.  Match the node's ACL2 events against
    // the traced axioms and show the distinct deciders.
    if (node.acl2_event && data.audit_details && data.audit_details.axioms_by_book) {
      const ev = String(node.acl2_event);
      const hits = [];
      Object.values(data.audit_details.axioms_by_book).forEach(list => list.forEach(a => {
        if (a.decider && ev.indexOf(a.name) !== -1) hits.push(a);
      }));
      const deciders = [...new Set(hits.map(a => a.decider))];
      if (deciders.length) {
        addDetailBlock(container, 'Who decides this',
          deciders.map(d => DECIDER_LABELS[d] || d).join(' · ') +
          (hits.length > 1 ? ` (${hits.length} axioms)` : ''));
      }
    } else if (node.axiom_free || (node.type === 'THEOREM' || node.type === 'LEMMA' || node.type === 'LIBRARY')) {
      addDetailBlock(container, 'Who decides this', 'Nobody — proved by ACL2 from definitions');
    }

    // Adversarial audit: is this axiom independent of the rest of its party's theory?
    if (node.acl2_event && data.meta && data.meta.adversarial_audit) {
      const ev = String(node.acl2_event);
      const hits = Object.entries(data.meta.adversarial_audit).filter(([name]) => ev.indexOf(name) !== -1);
      if (hits.length) {
        const lines = hits.map(([name, a]) => {
          const v = a.verdict === 'independent' ? 'independent — can be denied without disturbing any other premise'
                  : a.verdict === 'coupled' ? `coupled — denying it also falsifies: ${a.breaks.join(', ')} (a load-bearing joint / hinge)`
                  : a.verdict;
          return `${name}: ${v}` + (a.acl2 ? ` · ACL2: ${a.acl2}` : '');
        });
        addDetailBlock(container, 'Adversarial audit (is this premise load-bearing?)', lines.join('\n'));
      }
    }

    // #print-axioms analogue: the defaxioms in the closure of this node's book.
    if (node.book && data.meta && data.meta.trusted_base_by_book) {
      const key = String(node.book).replace(/\.lisp$/, '');
      const tb = data.meta.trusted_base_by_book[key];
      if (tb) {
        const by = Object.entries(tb.by_decider || {}).map(([d, n]) => `${n} ${d}`).join(', ');
        addDetailBlock(container, 'Trusted base of this book (#print axioms)',
          tb.count === 0 ? '0 axioms — everything in this book is proved from definitions'
                         : `${tb.count} axioms in the include-book closure (${by})`);
      }
    }

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
