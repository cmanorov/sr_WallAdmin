const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'sr_WallAdmin';
const uiContainer = document.getElementById('ui-container');
const closeBtn = document.getElementById('close-btn');

const baseInput = document.getElementById('toggle-base');
const subInputs = [
    { id: 'lines', input: document.getElementById('toggle-lines'), row: document.getElementById('row-lines') },
    { id: 'weapons', input: document.getElementById('toggle-weapons'), row: document.getElementById('row-weapons') },
    { id: 'vehicles', input: document.getElementById('toggle-vehicles'), row: document.getElementById('row-vehicles') }
];

async function fetchNui(eventName, data = {}) {
    try {
        const resp = await fetch(`https://${resourceName}/${eventName}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        return await resp.json();
    } catch (err) {
        // Ignora erros quando testando no navegador fora do FiveM
    }
}

function updateUI(states) {
    baseInput.checked = states.base;
    document.getElementById('row-base').classList.toggle('active', states.base);
    subInputs.forEach(sub => {
        sub.input.checked = states[sub.id];
        sub.row.classList.toggle('active', states[sub.id] && states.base);
        if (states.base) {
            sub.row.classList.remove('disabled');
            sub.input.disabled = false;
        } else {
            sub.row.classList.add('disabled');
            sub.input.disabled = true;
            sub.input.checked = false;
        }
    });
}

window.addEventListener('message', (event) => {
    const action = event.data.action;
    if (action === 'showUI') {
        updateUI(event.data.data);
        uiContainer.classList.remove('hidden');
    } else if (action === 'hideUI') {
        uiContainer.classList.add('hidden');
    }
});

function closeUI() {
    uiContainer.classList.add('hidden');
    fetchNui('close');
}

closeBtn.addEventListener('click', closeUI);
window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeUI();
});

document.querySelectorAll('input[type="checkbox"]').forEach(input => {
    input.addEventListener('change', (e) => {
        const moduleName = e.target.getAttribute('data-module');
        const isChecked = e.target.checked;
        const row = e.target.closest('.toggle-row');
        row.classList.toggle('active', isChecked);
        if (moduleName === 'base') {
            const states = { base: isChecked };
            subInputs.forEach(sub => states[sub.id] = sub.input.checked);
            updateUI(states);
        }
        fetchNui('toggleModule', {
            module: moduleName,
            state: isChecked
        });
    });
});