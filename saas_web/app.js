const form = document.getElementById('signup-form');
const messageDiv = document.getElementById('signup-message');

// Replace with the real signup endpoint when available
const SIGNUP_URL = 'SIGNUP_API_URL';

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  messageDiv.textContent = 'Signing you up...';
  const email = document.getElementById('email').value;
  try {
    const res = await fetch(SIGNUP_URL, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ email })
    });
    if (!res.ok) throw new Error('Failed');
    messageDiv.textContent = 'Check your email to complete signup.';
  } catch (err) {
    console.error(err);
    messageDiv.textContent = 'Signup failed. Please try again later.';
  }
});
