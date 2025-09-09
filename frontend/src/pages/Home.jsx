import React, { useState } from 'react';
import { uploadFile } from '../api';

function Home() {
  const [file, setFile] = useState(null);
  const [output, setOutput] = useState('');
  const [error, setError] = useState('');

  const handleUpload = async () => {
    if (!file) {
      setError('Please select a file to upload.');
      return;
    }
    const formData = new FormData();
    formData.append('file', file);
    try {
      setError('');
      const data = await uploadFile(formData);
      setOutput(data.text || '');
    } catch (err) {
      console.error('Upload failed:', err);
      setError('Upload failed. Please try again.');
    }
  };

  return (
    <div className='p-4'>
      <input type='file' onChange={e => setFile(e.target.files[0])} />
      <button onClick={handleUpload}>Generate Course</button>
      {error && <div className='text-red-600'>{error}</div>}
      <pre>{output}</pre>
    </div>
  );
}

export default Home;
