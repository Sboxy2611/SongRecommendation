// Ensure this port matches your Plumber configuration
const API_BASE_URL = 'http://127.0.0.1:8000';

// Handle Age Prediction
document.getElementById('btn-age').addEventListener('click', async () => {
    const resultDiv = document.getElementById('age-result');
    resultDiv.textContent = "Analyzing playlist temporal distribution...";
    resultDiv.classList.remove('hidden');

    try {
        const response = await fetch(`${API_BASE_URL}/predict_age`);
        const data = await response.json();
        resultDiv.innerHTML = `<strong>${data.message}</strong>`;
    } catch (error) {
        resultDiv.textContent = "Error connecting to R backend. Is Plumber running?";
        console.error(error);
    }
});

// Handle Song Recommendations
document.getElementById('btn-recommend').addEventListener('click', async () => {
    const songName = document.getElementById('song-input').value;
    const resultDiv = document.getElementById('reco-result');

    if (!songName) return;

    resultDiv.textContent = "Calculating cosine similarities...";
    resultDiv.classList.remove('hidden');

    try {
        const response = await fetch(`${API_BASE_URL}/recommend`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ track_name: songName })
        });
        
        const data = await response.json();

        // Handle error if song isn't in the dataset
        if (data.error) {
            resultDiv.textContent = data.error;
            return;
        }

        // Render recommended tracks
        resultDiv.innerHTML = '<h3 style="margin-top: 0;">Top 5 Audio Matches:</h3>';
        data.forEach(track => {
            const trackEl = document.createElement('div');
            trackEl.className = 'track-item';
            trackEl.innerHTML = `
                <div class="track-title">${track.track_name}</div>
                <div class="track-artist">${track.track_artist} &bull; ${track.track_album_name}</div>
            `;
            resultDiv.appendChild(trackEl);
        });
    } catch (error) {
        resultDiv.textContent = "Error fetching recommendations.";
        console.error(error);
    }
});