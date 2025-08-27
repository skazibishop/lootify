const NUI = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lootify';

function nui(name, data) {
  return fetch(`https://${NUI}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data || {}) }).then(r => r.json()).catch(() => ({ ok: false, err: 'nui_error' }));
}
function send(name, data) {
  fetch(`https://${NUI}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data || {}) });
}

const $ = (sel) => document.querySelector(sel);
const state = { data: null, drag: null };

function setStatus(s) { const el = $('#status'); if (el) el.textContent = s; }

function cellSize() {
  const g = document.querySelector('.grid');
  if (!g) return 34;
  const v = getComputedStyle(g).getPropertyValue('--cell');
  const n = parseInt(v, 10);
  return Number.isFinite(n) && n > 0 ? n : 34;
}

function render(data) {
  if (!data) { console.warn('render(): no data'); return; }
  state.data = data;
  const pn = $('#playerName'); if (pn) pn.textContent = `Jogador: ${data?.name || '-'}`;
  renderGrid('#grid-player', data.player, 'main');
  renderContainers('#player-containers', data.containers);
  renderGrid('#grid-stash', data.stash, 'main');
  renderEquip('#equip', data.equip);
}



function renderGrid(selector, inv, gridKey) {
  const el = $(selector);
  if (!el) { console.warn('renderGrid: missing element', selector); return; }
  if (!inv) { console.warn('renderGrid: missing inv for', selector); return; }

  const findGridSize = (inv, key) => {
    if (inv.grids) {
      const g = (inv.grids || []).find(x => x.key === key);
      if (g) return { w: g.w, h: g.h };
    }
    return inv.size || { w: 10, h: 18 };
  };
  const size = findGridSize(inv, gridKey);
  if (!size || !size.w || !size.h) { console.warn('renderGrid: bad size for', selector, size); return; }

  el.style.setProperty('--w', size.w);
  el.style.setProperty('--h', size.h);
  el.innerHTML = '';

  const hl = document.createElement('div');
  hl.className = 'highlight bad';
  hl.style.display = 'none';
  el.appendChild(hl);

  (inv.items || []).forEach(it => {
    const key = (it.grid_key || 'main');
    if (key !== gridKey) return;
    const d = document.createElement('div');
    d.className = 'item';
    const rot = (it.rot || 0) === 1;
    const wCells = rot ? it.size_h : it.size_w;
    const hCells = rot ? it.size_w : it.size_h;
    d.style.width = `${wCells * cellSize()}px`;
    d.style.height = `${hCells * cellSize()}px`;
    d.style.transform = `translate(${(it.pos_x || 0) * cellSize()}px, ${(it.pos_y || 0) * cellSize()}px)`;
    d.dataset.inv = inv.id;
    d.dataset.id = it.id;
    d.dataset.name = it.name;
    d.dataset.gridKey = key;
    d.dataset.w = it.size_w;
    d.dataset.h = it.size_h;
    d.dataset.rot = it.rot || 0;
    d.innerHTML = `<div class="label">${it.name} ×${it.amount || 1}</div>`;

    d.addEventListener('mousedown', (e) => beginDrag(e, d, inv));
    d.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      const count = prompt('Dividir quantidade em nova pilha:');
      const n = parseInt(count || '0', 10);
      if (!n || n <= 0) return;
      setStatus('dividindo...');
      nui('split', { inv_id: inv.id, item_id: it.id, count: n }).then(r => {
        setStatus(r.ok ? 'divisão ok' : 'erro: ' + (r.err || 'desconhecido'));
      });
    });

    el.appendChild(d);
  });

  el._highlight = hl;
  el._inv = inv;
  el._gridKey = gridKey;
  el.dataset.inv = inv.id;
  el.dataset.gridKey = gridKey;
}

function computeAutoLayout(grids) {
  const gs = Array.isArray(grids) ? [...grids] : [];
  if (gs.length === 0) return { cols: 1, rows: 1, cells: [] };

  // 1) escolhe o "principal": bp_main > main > maior área
  let mainIdx = gs.findIndex(g => g.key === 'bp_main' || g.key === 'main');
  if (mainIdx === -1) {
    let max = -1; mainIdx = 0;
    gs.forEach((g, i) => { const a = (g.w||0)*(g.h||0); if (a > max) { max = a; mainIdx = i; } });
  }
  const main = gs.splice(mainIdx, 1)[0];

  // 2) ordena bolsos p1..pN primeiro, depois os demais por nome
  const numFirst = gs.filter(g => /_p(\d+)$/i.test(g.key))
    .sort((a,b)=>parseInt(a.key.match(/_p(\d+)$/i)[1],10)-parseInt(b.key.match(/_p(\d+)$/i)[1],10));
  const others = gs.filter(g => !/_p(\d+)$/i.test(g.key))
    .sort((a,b)=>a.key.localeCompare(b.key, 'en', {numeric:true, sensitivity:'base'}));

  const rest = [...numFirst, ...others];

  // 3) grade de 2 colunas: main ocupa 2 colunas na 1ª linha; bolsos descem alternando
  const cols = 2;
  const cells = [{ key: main.key, col: 1, row: 1, colSpan: 2 }];
  let row = 2, col = 1;
  for (const g of rest) {
    cells.push({ key: g.key, col, row });
    col = (col === 1) ? 2 : 1;
    if (col === 1) row++;
  }
  const rows = Math.max(1, 1 + Math.ceil(rest.length/2));
  return { cols, rows, cells };
}


function renderContainers(selector, containers){
  const wrap = document.querySelector(selector);
  if(!wrap) return;
  wrap.innerHTML = '';

  (containers||[]).forEach(cont => {
    const box = document.createElement('div');
    box.className = 'panel';
    box.style.background = 'transparent';
    box.style.border = '0';

    const title = document.createElement('h3');
    title.textContent = `Container: ${cont.slot}`;
    box.appendChild(title);

    // layout calculado só a partir de cont.grids (sem layout do servidor)
    const layout = computeAutoLayout(cont.grids || []);
    const gridsWrap = document.createElement('div');
    gridsWrap.className = 'container-layout';
    gridsWrap.style.gridTemplateColumns = `repeat(${layout.cols}, max-content)`;
    gridsWrap.style.gridTemplateRows = `repeat(${layout.rows}, max-content)`;

    // cria todos os holders + inners ANTES de renderGrid
    const created = new Set();
    for(const cell of layout.cells){
      const holder = document.createElement('div');
      holder.className = 'grid';
      holder.style.gridColumn = `${cell.col} / span ${cell.colSpan||1}`;
      holder.style.gridRow    = `${cell.row} / span ${cell.rowSpan||1}`;

      const inner = document.createElement('div');
      inner.className = 'grid-inner';
      inner.id = `grid-${cont.id}-${cell.key}`;
      holder.appendChild(inner);
      gridsWrap.appendChild(holder);
      created.add(cell.key);
    }

    // fallback defensivo: se existir grid no meta mas sem célula criada, cria numa linha extra
    if (Array.isArray(cont.grids)) {
      let extraRow = layout.rows + 1, extraCol = 1;
      for (const g of cont.grids) {
        if (created.has(g.key)) continue;
        const holder = document.createElement('div');
        holder.className = 'grid';
        holder.style.gridColumn = `${extraCol} / span 1`;
        holder.style.gridRow    = `${extraRow} / span 1`;

        const inner = document.createElement('div');
        inner.className = 'grid-inner';
        inner.id = `grid-${cont.id}-${g.key}`;
        holder.appendChild(inner);
        gridsWrap.appendChild(holder);

        extraCol = (extraCol === 1) ? 2 : 1;
        if (extraCol === 1) extraRow++;
      }
    }

    box.appendChild(gridsWrap);
    wrap.appendChild(box);

    // só aqui chamamos renderGrid, quando TODOS os elementos existem
    const allKeys = Array.from(created);
    if (Array.isArray(cont.grids)) {
      for (const g of cont.grids) if (!created.has(g.key)) allKeys.push(g.key);
    }
    for (const key of allKeys) {
      const sel = `#grid-${cont.id}-${key}`;
      renderGrid(sel, cont, key);
    }
  });
}



function renderEquip(selector, equip) {
  const list = $(selector);
  if (!list) return;
  list.innerHTML = '';
  const grids = equip?.grids || [];
  const itemsBySlot = {};
  (equip?.items || []).forEach(it => { itemsBySlot[it.grid_key || ''] = it; });

  grids.forEach(g => {
    const slot = document.createElement('div');
    slot.className = 'equip-slot';
    slot.dataset.slot = g.key;
    slot.innerHTML = `<div class="slot-title">${g.key}</div>`;
    const it = itemsBySlot[g.key];
    if (it) {
      const chip = document.createElement('div');
      chip.className = 'slot-item';
      chip.textContent = `${it.name} ×${it.amount || 1}`;
      chip.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        setStatus('removendo...');
        nui('unequip', { slot_key: g.key }).then(r => setStatus(r.ok ? 'removido' : 'erro: ' + (r.err || 'desconhecido')));
      });
      slot.appendChild(chip);
    } else {
      slot.addEventListener('mouseup', (e) => {
        if (!state.drag) return;
        if (state.drag.fromInv && state.drag.item) {
          setStatus('equipando...');
          nui('equip', { from_inv: state.drag.fromInv, item_id: state.drag.item.id, slot_key: g.key }).then(r => {
            setStatus(r.ok ? 'equipado' : 'erro: ' + (r.err || 'desconhecido'));
          });
        }
        endDrag();
      });
    }
    list.appendChild(slot);
  });
}

function beginDrag(e, itemEl, inv) {
  const it = {
    id: parseInt(itemEl.dataset.id, 10),
    name: itemEl.dataset.name,
    size_w: parseInt(itemEl.dataset.w, 10),
    size_h: parseInt(itemEl.dataset.h, 10),
    rot: parseInt(itemEl.dataset.rot, 10),
    grid_key: itemEl.dataset.gridKey || 'main'
  };
  state.drag = {
    item: it,
    fromInv: inv.id,
    rot: it.rot || 0,
    ghost: makeGhost(itemEl, e.clientX, e.clientY),
    target: null,
    last: { x: e.clientX, y: e.clientY }
  };
  itemEl.classList.add('dragging');
  document.addEventListener('mousemove', onDragMove);
  document.addEventListener('mouseup', onDragEnd);
  document.addEventListener('keydown', onDragKey);
}

function makeGhost(itemEl, x, y) {
  const g = document.createElement('div');
  g.className = 'ghost';
  g.style.width = getComputedStyle(itemEl).width;
  g.style.height = getComputedStyle(itemEl).height;
  g.style.left = (x - 12) + 'px';
  g.style.top = (y - 12) + 'px';
  document.body.appendChild(g);
  return g;
}

function onDragKey(e) {
  if (!state.drag) return;
  if (e.key.toLowerCase() === 'r') {
    state.drag.rot = state.drag.rot === 1 ? 0 : 1;
    const w = state.drag.rot === 1 ? state.drag.item.size_h : state.drag.item.size_w;
    const h = state.drag.rot === 1 ? state.drag.item.size_w : state.drag.item.size_h;
    if (state.drag.ghost) {
      state.drag.ghost.style.width = (w * cellSize()) + 'px';
      state.drag.ghost.style.height = (h * cellSize()) + 'px';
    }
    if (state.drag.target) updateHighlight(state.drag.target.gridEl, state.drag.target.cellX, state.drag.target.cellY, w, h);
  }
}

function onDragMove(e) {
  if (!state.drag) return;
  const g = state.drag.ghost;
  if (g) { g.style.left = (e.clientX - 12) + 'px'; g.style.top = (e.clientY - 12) + 'px'; }
  state.drag.last = { x: e.clientX, y: e.clientY };

  const grids = Array.from(document.querySelectorAll('.grid-inner')).map(el => ({ sel: '#' + (el.id || ''), el }));
  let over = null;
  for (const gr of grids) {
    const rect = gr.el.getBoundingClientRect();
    if (e.clientX >= rect.left && e.clientX <= rect.right && e.clientY >= rect.top && e.clientY <= rect.bottom) {
      over = gr; break;
    }
  }
  if (!over) {
    hideAllHighlights();
    state.drag.target = null;
    return;
  }

  const inv = over.el._inv;
  const gridKey = over.el._gridKey || 'main';
  const rect = over.el.getBoundingClientRect();
  const cx = Math.floor((e.clientX - rect.left) / cellSize());
  const cy = Math.floor((e.clientY - rect.top) / cellSize());
  const w = state.drag.rot === 1 ? state.drag.item.size_h : state.drag.item.size_w;
  const h = state.drag.rot === 1 ? state.drag.item.size_w : state.drag.item.size_h;

  updateHighlight(over.el, cx, cy, w, h);
  state.drag.target = { inv, gridEl: over.el, invId: inv?.id, gridKey, cellX: cx, cellY: cy };
}

function hideAllHighlights() {
  for (const el of document.querySelectorAll('.grid-inner')) {
    if (el && el._highlight) { el._highlight.style.display = 'none'; }
  }
}

function updateHighlight(gridEl, cx, cy, w, h) {
  if (!gridEl) return;
  const inv = gridEl._inv;
  if (!inv) return;
  const findGridSize = (inv, key) => {
    if (inv.grids) {
      const g = (inv.grids || []).find(x => x.key === key);
      if (g) return { w: g.w, h: g.h };
    }
    return inv.size || { w: 10, h: 18 };
  };
  const size = findGridSize(inv, gridEl._gridKey || 'main');
  const hl = gridEl._highlight;
  if (!hl || !size) return;

  let ok = true;
  if (cx < 0 || cy < 0 || cx + w > size.w || cy + h > size.h) ok = false;
  if (ok) {
    for (const it of (inv.items || [])) {
      if ((it.grid_key || 'main') !== (gridEl._gridKey || 'main')) continue;
      const rot = (it.rot || 0) === 1;
      const iw = rot ? it.size_h : it.size_w;
      const ih = rot ? it.size_w : it.size_h;
      if (!(cx + w - 1 < it.pos_x || it.pos_x + iw - 1 < cx || cy + h - 1 < it.pos_y || it.pos_y + ih - 1 < cy)) {
        ok = false; break;
      }
    }
  }

  hl.classList.toggle('bad', !ok);
  hl.style.display = 'block';
  hl.style.width = (w * cellSize()) + 'px';
  hl.style.height = (h * cellSize()) + 'px';
  hl.style.transform = `translate(${cx * cellSize()}px, ${cy * cellSize()}px)`;
}

function onDragEnd(e) {
  endDrag(true);
}

function endDrag(commit) {
  document.removeEventListener('mousemove', onDragMove);
  document.removeEventListener('mouseup', onDragEnd);
  document.removeEventListener('keydown', onDragKey);
  document.querySelectorAll('.item.dragging').forEach(el => el.classList.remove('dragging'));
  if (!state.drag) { hideAllHighlights(); return; }

  const d = state.drag;
  const target = d.target;

  if (commit && d.last) {
    const elem = document.elementFromPoint(d.last.x, d.last.y);
    const itemEl = elem && (elem.classList.contains('item') ? elem : (elem.closest && elem.closest('.item')));
    if (itemEl) {
      const targetInv = parseInt(itemEl.dataset.inv, 10);
      const targetId = parseInt(itemEl.dataset.id, 10);
      if (targetInv && targetId && targetInv === d.fromInv && targetId !== d.item.id) {
        setStatus('empilhando...');
        nui('stack', { inv_id: targetInv, from_item_id: d.item.id, to_item_id: targetId }).then(r => {
          setStatus(r.ok ? 'empilhado' : 'erro: ' + (r.err || 'desconhecido'));
        });
        if (d.ghost && d.ghost.parentNode) d.ghost.parentNode.removeChild(d.ghost);
        state.drag = null;
        hideAllHighlights();
        return;
      }
    }
  }

  if (commit && target && target.invId) {
    setStatus('movendo...');
    nui('move', {
      from_inv: d.fromInv,
      to_inv: target.invId,
      item_id: d.item.id,
      to_pos: { x: target.cellX, y: target.cellY },
      rot: d.rot,
      grid_key: target.gridKey
    }).then(r => {
      setStatus(r.ok ? 'movido' : 'erro: ' + (r.err || 'desconhecido'));
    });
  }
  if (d.ghost && d.ghost.parentNode) d.ghost.parentNode.removeChild(d.ghost);
  state.drag = null;
  hideAllHighlights();
}

// NUI events
window.addEventListener('message', (e) => {
  const { t, data } = e.data || {};
  if (t === 'open') { render(data); document.body.style.display = 'block'; }
  else if (t === 'sync') { render(data); }
});

const btn = document.getElementById('closeBtn');
if (btn) btn.addEventListener('click', () => send('close'));
document.body.style.display = 'none';
