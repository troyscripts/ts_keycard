'use strict';
const viewer = document.getElementById('viewer');
window.addEventListener('message', ({ data }) => {
  if (!data || !['open', 'close'].includes(data.action)) return;
  if (data.action === 'close') { viewer.hidden = true; return; }
  if (!data.card) return;
  for (const key of ['name', 'rank', 'station']) {
    document.getElementById(key).textContent = String(data.card[key] ?? 'Onbekend');
  }
  viewer.hidden = false;
  document.getElementById('close').focus();
});
async function closeCard() {
  viewer.hidden = true;
  if (typeof GetParentResourceName !== 'function') return;
  try {
    await fetch(`https://${GetParentResourceName()}/close`, {
      method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: '{}'
    });
  } catch (error) { console.error('Kaart sluiten mislukt:', error); }
}
document.getElementById('close').addEventListener('click', closeCard);
document.addEventListener('keydown', (event) => { if (event.key === 'Escape') closeCard(); });
