.pragma library

// Panel / widget layout operations for BarConfig.
// Each function receives the BarConfig singleton as `root`.

function getWidgetPanelIndex(root, widgetId) {
  let pList = root.panels || [];
  for (let i = 0; i < pList.length; i++) {
    if ((pList[i] || []).indexOf(widgetId) !== -1) return i;
  }
  return -1;
}

function getWidgetSection(root, widgetId) {
  let idx = root.getWidgetPanelIndex(widgetId);
  if (idx === -1) return "none";
  const n = root.panels.length;
  if (idx === 0) return "left";
  if (idx === n - 1 && n > 1) return "right";
  return "center";
}

function _setCurrentBarPanels(root, newPanels) {
  const tgt = (root.currentBar ? (root.currentBar.displayTarget || (root.currentBar.allMonitors ? "all" : "primary")) : "primary");
  if (tgt === "all" && root.activeEditingDisplay === "secondary") {
    root.updateBarProp("secondaryPanels", newPanels, root.selectedBarIndex);
  } else {
    root.updateBarProp("panels", newPanels, root.selectedBarIndex);
  }
  root.panelsRevision++;
  root.panelsUpdated();
}

function isSecondaryWidgetActive(root, widgetId) {
  const sPanels = (root.currentBar && root.currentBar.secondaryPanels)
    ? root.currentBar.secondaryPanels
    : root.defaultSecondaryPanels;
  for (let p = 0; p < sPanels.length; p++) {
    if ((sPanels[p] || []).indexOf(widgetId) !== -1) return true;
  }
  return false;
}

function toggleSecondaryWidget(root, widgetId) {
  let pList = ((root.currentBar && root.currentBar.secondaryPanels && root.currentBar.secondaryPanels.length > 0)
    ? root.currentBar.secondaryPanels
    : root.defaultSecondaryPanels).map(arr => (arr || []).slice());

  while (pList.length < 3) pList.push([]);

  let exists = false;
  for (let p = 0; p < pList.length; p++) {
    const idx = pList[p].indexOf(widgetId);
    if (idx !== -1) {
      pList[p].splice(idx, 1);
      exists = true;
      break;
    }
  }

  if (!exists) {
    let targetIdx = 0;
    if (["clock", "weather", "battery", "media", "tray", "controlCenter", "idleInhibitor"].indexOf(widgetId) !== -1) {
      targetIdx = pList.length - 1;
    } else if (["windowTitle", "cava"].indexOf(widgetId) !== -1) {
      targetIdx = Math.floor(pList.length / 2);
    } else {
      targetIdx = 0;
    }
    pList[targetIdx].push(widgetId);
  }

  root.updateBarProp("secondaryPanels", pList, root.selectedBarIndex);
  root.panelsRevision++;
  root.panelsUpdated();
}

function applySecondaryPreset(root, presetName) {
  let newPanels = [];
  if (presetName === "minimal") {
    newPanels = [["workspaces"], [], ["clock"]];
  } else if (presetName === "media") {
    newPanels = [["workspaces"], ["windowTitle", "cava"], ["media", "clock"]];
  } else if (presetName === "sysinfo") {
    newPanels = [["workspaces"], ["cpu", "temp", "memory"], ["clock"]];
  } else if (presetName === "full") {
    newPanels = [
      ["appGrid", "workspaces"],
      ["windowTitle", "cava"],
      ["weather", "media", "clock"]
    ];
  }
  root.updateBarProp("secondaryPanels", newPanels, root.selectedBarIndex);
  root.panelsRevision++;
  root.panelsUpdated();
}

// Add a new blank panel section to the selected Bar (up to 6 panels)
function addBlankPanel(root) {
  let pList = (root.panels || []).map(arr => (arr || []).slice());
  if (pList.length >= 6) return;
  pList.push([]);
  root._setCurrentBarPanels(pList);
}

// Remove a specific panel section by index; any widgets inside return to the Available Pool
function removePanelAt(root, panelIndex) {
  let pList = (root.panels || []).map(arr => (arr || []).slice());
  if (pList.length <= 1 || panelIndex < 0 || panelIndex >= pList.length) return;
  let removedItems = pList[panelIndex] || [];
  pList.splice(panelIndex, 1);
  let rem = (root.removedWidgets || []).slice();
  for (let i = 0; i < removedItems.length; i++) {
    if (rem.indexOf(removedItems[i]) === -1) rem.push(removedItems[i]);
  }
  root.removedWidgets = rem;
  root._setCurrentBarPanels(pList);
}

// Set exact number of panels (e.g. 2, 3, 4, 5) - adds blank panels or removes trailing panels
function setPanelCount(root, targetCount) {
  targetCount = Math.max(1, Math.min(6, Number(targetCount) || 3));
  let pList = (root.panels || []).map(arr => (arr || []).slice());
  let rem = (root.removedWidgets || []).slice();

  while (pList.length < targetCount) {
    pList.push([]);
  }
  while (pList.length > targetCount) {
    let popped = pList.pop() || [];
    for (let i = 0; i < popped.length; i++) {
      if (rem.indexOf(popped[i]) === -1) rem.push(popped[i]);
    }
  }
  root.removedWidgets = rem;
  root._setCurrentBarPanels(pList);
}

function canAddWidgetToPanel(root, widgetId, targetPanelIndex) {
  const pList = root.panels || [];
  if (targetPanelIndex < 0 || targetPanelIndex >= pList.length) return false;
  const list = pList[targetPanelIndex] || [];
  if (list.indexOf(widgetId) !== -1) return true;
  return list.length < root.maxPanelWidgets;
}

function setWidgetPanel(root, widgetId, targetPanelIndex) {
  if (targetPanelIndex >= 0 && targetPanelIndex < (root.panels || []).length) {
    if (!root.canAddWidgetToPanel(widgetId, targetPanelIndex)) {
      root.configWarning("Already maxed out, please move somewhere else");
      return false;
    }
  }

  let pList = (root.panels || []).map(arr => (arr || []).filter(w => w !== widgetId));
  let rem = (root.removedWidgets || []).filter(w => w !== widgetId);

  if (targetPanelIndex >= 0 && targetPanelIndex < pList.length) {
    pList[targetPanelIndex].push(widgetId);
  } else {
    rem.push(widgetId);
  }

  root.removedWidgets = rem;
  root._setCurrentBarPanels(pList);
  return true;
}

function setWidgetSection(root, widgetId, targetSection) {
  if (targetSection === "none") {
    root.setWidgetPanel(widgetId, -1);
    return;
  }
  if (typeof targetSection === "number") {
    root.setWidgetPanel(widgetId, targetSection);
    return;
  }
  const n = root.panels.length;
  if (targetSection === "left") root.setWidgetPanel(widgetId, 0);
  else if (targetSection === "right") root.setWidgetPanel(widgetId, Math.max(0, n - 1));
  else root.setWidgetPanel(widgetId, n > 2 ? 1 : 0);
}

function addWidgetToPanel(root, widgetId, panelIndex) {
  let idx = (panelIndex !== undefined && panelIndex >= 0 && panelIndex < (root.panels || []).length) ? panelIndex : 0;
  if (!root.canAddWidgetToPanel(widgetId, idx)) {
    let found = -1;
    const pList = root.panels || [];
    for (let p = 0; p < pList.length; p++) {
      if (root.canAddWidgetToPanel(widgetId, p)) {
        found = p;
        break;
      }
    }
    if (found !== -1) {
      idx = found;
    } else {
      root.configWarning("Already maxed out, please move somewhere else");
      return false;
    }
  }
  root.setWidgetVisible(widgetId, true, undefined, true);
  return root.setWidgetPanel(widgetId, idx);
}

function addWidgetToSection(root, widgetId, targetSection) {
  root.setWidgetVisible(widgetId, true);
  let targetIdx = 0;
  const n = root.panels.length;
  if (targetSection === "left") targetIdx = 0;
  else if (targetSection === "right") targetIdx = Math.max(0, n - 1);
  else targetIdx = n > 2 ? 1 : 0;
  return root.addWidgetToPanel(widgetId, targetIdx);
}

function removeWidgetFromBar(root, widgetId) {
  root.setWidgetPanel(widgetId, -1);
}

function moveWidgetUp(root, widgetId) {
  let pIdx = root.getWidgetPanelIndex(widgetId);
  if (pIdx === -1) return;
  let pList = (root.panels || []).map(arr => (arr || []).slice());
  let list = pList[pIdx];
  let idx = list.indexOf(widgetId);
  if (idx > 0) {
    let temp = list[idx - 1];
    list[idx - 1] = list[idx];
    list[idx] = temp;
    root._setCurrentBarPanels(pList);
  }
}

function moveWidgetDown(root, widgetId) {
  let pIdx = root.getWidgetPanelIndex(widgetId);
  if (pIdx === -1) return;
  let pList = (root.panels || []).map(arr => (arr || []).slice());
  let list = pList[pIdx];
  let idx = list.indexOf(widgetId);
  if (idx !== -1 && idx < list.length - 1) {
    let temp = list[idx + 1];
    list[idx + 1] = list[idx];
    list[idx] = temp;
    root._setCurrentBarPanels(pList);
  }
}

function moveWidgetSectionLeft(root, widgetId) {
  let pIdx = root.getWidgetPanelIndex(widgetId);
  if (pIdx > 0) {
    if (!root.canAddWidgetToPanel(widgetId, pIdx - 1)) {
      root.configWarning("Already maxed out, please move somewhere else");
      return false;
    }
    return root.setWidgetPanel(widgetId, pIdx - 1);
  }
  return false;
}

function moveWidgetSectionRight(root, widgetId) {
  let pIdx = root.getWidgetPanelIndex(widgetId);
  if (pIdx !== -1 && pIdx < root.panels.length - 1) {
    if (!root.canAddWidgetToPanel(widgetId, pIdx + 1)) {
      root.configWarning("Already maxed out, please move somewhere else");
      return false;
    }
    return root.setWidgetPanel(widgetId, pIdx + 1);
  }
  return false;
}

function moveWidgetToPanelAt(root, widgetId, targetPanelIndex, targetItemIndex) {
  if (!widgetId) return false;
  let pList = (root.panels || []).map(arr => (arr || []).slice());
  let rem = (root.removedWidgets || []).filter(w => w !== widgetId);

  // Target < 0 means drop into the unassigned pool
  if (targetPanelIndex < 0 || targetPanelIndex >= pList.length) {
    pList = pList.map(arr => arr.filter(w => w !== widgetId));
    if (rem.indexOf(widgetId) === -1) rem.push(widgetId);
    root.removedWidgets = rem;
    root._setCurrentBarPanels(pList);
    return true;
  }

  let srcPanelIndex = -1;
  let srcItemIndex = -1;
  for (let p = 0; p < pList.length; p++) {
    let existingIdx = pList[p].indexOf(widgetId);
    if (existingIdx !== -1) {
      srcPanelIndex = p;
      srcItemIndex = existingIdx;
      break;
    }
  }

  // Check capacity if moving from a different panel or unassigned pool
  if (srcPanelIndex !== targetPanelIndex && pList[targetPanelIndex].length >= root.maxPanelWidgets) {
    root.configWarning("Already maxed out, please move somewhere else");
    return false;
  }

  if (srcPanelIndex !== -1) {
    pList[srcPanelIndex].splice(srcItemIndex, 1);
  }

  let destList = pList[targetPanelIndex];
  let adjustedTargetIdx = targetItemIndex;
  if (srcPanelIndex === targetPanelIndex && srcItemIndex !== -1 && targetItemIndex !== undefined && targetItemIndex > srcItemIndex) {
    adjustedTargetIdx = targetItemIndex - 1;
  }

  let insertIdx = (adjustedTargetIdx === undefined || adjustedTargetIdx < 0)
    ? destList.length
    : Math.max(0, Math.min(destList.length, adjustedTargetIdx));
  destList.splice(insertIdx, 0, widgetId);

  root.removedWidgets = rem;
  root.setWidgetVisible(widgetId, true, undefined, true);
  root._setCurrentBarPanels(pList);
  return true;
}

function _resolveBarId(root, barId) {
  if (barId && String(barId).trim() !== "") return String(barId).trim();
  return (root.currentBar && root.currentBar.id) ? String(root.currentBar.id) : "bar_1";
}

function isWidgetVisible(root, widgetId, barId) {
  if (root.widgetVisibilityChangeCounter < 0) return false;
  void root.selectedBarIndex;
  const bId = root._resolveBarId(barId);
  const token = "@hidden:" + bId + ":" + widgetId;
  const rem = root.removedWidgets || [];
  for (let i = 0; i < rem.length; i++) {
    if (String(rem[i]) === token) return false;
  }
  return true;
}

function setWidgetVisible(root, widgetId, val, barId, skipSave) {
  if (!widgetId) return;
  const bId = root._resolveBarId(barId);
  const token = "@hidden:" + bId + ":" + widgetId;
  let rem = (root.removedWidgets || []).filter(item => String(item) !== token);
  if (!val) {
    rem.push(token);
  }
  root.removedWidgets = rem;
  root.widgetVisibilityChangeCounter++;
  if (!skipSave) {
    root.saveConfig();
  }
}

function isWidgetInAnyBar(root, widgetId) {
  if (!root.bars) return false;
  for (let i = 0; i < root.bars.length; i++) {
    const b = root.bars[i];
    if (b && b.enabled !== false) {
      if (b.panels) {
        for (let p = 0; p < b.panels.length; p++) {
          if (b.panels[p] && b.panels[p].indexOf(widgetId) !== -1) {
            return true;
          }
        }
      }
      if (b.secondaryPanels) {
        for (let p = 0; p < b.secondaryPanels.length; p++) {
          if (b.secondaryPanels[p] && b.secondaryPanels[p].indexOf(widgetId) !== -1) {
            return true;
          }
        }
      }
    }
  }
  return false;
}
