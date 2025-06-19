const statusDiv = document.getElementById('status');
const startBtn = document.getElementById('start-btn');

// Replace these at deploy time with the actual API Gateway URLs
const STATUS_URL = 'STATUS_API_URL';
const START_URL = 'START_API_URL';

async function fetchStatus() {
  try {
    const res = await fetch(STATUS_URL);
    const data = await res.json();
    if (data.state === 'running') {
      const players = data.players !== null && data.players !== undefined ? data.players : 0;
      statusDiv.textContent = `Server is running with ${players} player${players === 1 ? '' : 's'} online.`;
      startBtn.style.display = 'none';
    } else {
      statusDiv.textContent = 'Server is offline.';
      startBtn.style.display = 'inline-block';
    }
  } catch (err) {
    console.error(err);
    statusDiv.textContent = 'Error fetching status.';
  }
}

startBtn.addEventListener('click', async () => {
  startBtn.disabled = true;
  startBtn.textContent = 'Starting...';
  try {
    const res = await fetch(START_URL, { method: 'POST' });
    if (!res.ok) throw new Error('Failed');
  } catch (err) {
    alert('Could not start server');
    console.error(err);
  }
});

fetchStatus();
setInterval(fetchStatus, 30000);
