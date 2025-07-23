import React, { useState } from 'react';
function Home() {
  const [file, setFile] = useState(null);
  const [output, setOutput] = useState('');
  const handleUpload = async () => {
    const formData = new FormData();
    formData.append('file', file);
    const res = await fetch('/generate', { method: 'POST', body: formData });
    const data = await res.json();
    setOutput(data.course);
  };
  return (
    <div className='p-4'>
      <input type='file' onChange={e => setFile(e.target.files[0])} />
      <button onClick={handleUpload}>Generate Course</button>
      <pre>{output}</pre>
    </div>
  );
}
export default Home;
