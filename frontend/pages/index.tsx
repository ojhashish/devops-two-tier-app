// frontend/pages/index.tsx
import { useState, useEffect } from 'react';
import type { NextPage } from 'next';

const Home: NextPage = () => {
  const [message, setMessage] = useState<string>('Loading backend message...');
  const [health, setHealth] = useState<string>('Checking backend health...');

  // For local development, this defaults to localhost:5001
  const BACKEND_URL: string = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:5001';

  useEffect(() => {
    fetch(`${BACKEND_URL}/health`)
      .then(res => {
        if (!res.ok) {
          throw new Error(`HTTP error! status: ${res.status}`);
        }
        return res.json();
      })
      .then((data: { status: string }) => setHealth(`Backend Health: ${data.status}`))
      .catch((error: Error) => setHealth(`Backend Health: Error - ${error.message}`));

    fetch(`${BACKEND_URL}/api/message`)
      .then(res => {
        if (!res.ok) {
          throw new Error(`HTTP error! status: ${res.status}`);
        }
        return res.json();
      })
      .then((data: { message: string }) => setMessage(`Backend Message: ${data.message}`))
      .catch((error: Error) => setMessage(`Backend Message: Error - ${error.message}`));
  }, []);

  return (
    <div style={{ fontFamily: 'Arial, sans-serif', padding: '20px', textAlign: 'center' }}>
      <h1>My Two-Tier App</h1>
      <p style={{ fontSize: '1.2em', color: '#333' }}>{health}</p>
      <p style={{ fontSize: '1.2em', color: '#333' }}>{message}</p>
      <div style={{ marginTop: '30px', borderTop: '1px solid #eee', paddingTop: '20px' }}>
        <p style={{ fontSize: '0.9em', color: '#666' }}>
          This is a simple Next.js frontend calling a Python Flask backend.
        </p>
        <p style={{ fontSize: '0.9em', color: '#666' }}>
          Backend Health: `/health` | Backend Message: `/api/message`
        </p>
      </div>
    </div>
  );
};
export default Home;














