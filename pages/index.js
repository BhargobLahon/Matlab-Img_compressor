import { useState } from 'react';
import styles from '../styles/Home.module.css';

export default function Home() {
  const [file, setFile] = useState(null);
  const [targetSize, setTargetSize] = useState(500);
  const [resizeFactor, setResizeFactor] = useState(1);
  const [status, setStatus] = useState('');
  const [resultImage, setResultImage] = useState(null);
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!file) return;
    
    const formData = new FormData();
    formData.append('image', file);
    formData.append('targetSize', targetSize);
    formData.append('resizeFactor', resizeFactor);
    
    setStatus('Uploading and processing...');
    
    try {
      const response = await fetch('/api/compress', {
        method: 'POST',
        body: formData,
      });
      
      if (!response.ok) throw new Error('Failed to compress image');
      
      const blob = await response.blob();
      const imageUrl = URL.createObjectURL(blob);
      
      setResultImage(imageUrl);
      setStatus('Compression complete!');
    } catch (error) {
      setStatus(`Error: ${error.message}`);
    }
  };
  
  return (
    <div className={styles.container}>
      <main className={styles.main}>
        <h1 className={styles.title}>MATLAB JPEG Compression</h1>
        
        <form onSubmit={handleSubmit} className={styles.form}>
          <div className={styles.formGroup}>
            <label htmlFor="image">Select Image:</label>
            <input 
              type="file" 
              id="image" 
              accept="image/*" 
              onChange={(e) => setFile(e.target.files[0])}
              required 
            />
          </div>
          
          <div className={styles.formGroup}>
            <label htmlFor="targetSize">
              Target Size (KB): {targetSize}
            </label>
            <input 
              type="range" 
              id="targetSize" 
              min="50" 
              max="2000" 
              value={targetSize}
              onChange={(e) => setTargetSize(e.target.value)} 
            />
          </div>
          
          <div className={styles.formGroup}>
            <label htmlFor="resizeFactor">
              Resize Factor: {resizeFactor}
            </label>
            <input 
              type="range" 
              id="resizeFactor" 
              min="0.1" 
              max="1" 
              step="0.1"
              value={resizeFactor}
              onChange={(e) => setResizeFactor(e.target.value)} 
            />
          </div>
          
          <button type="submit" className={styles.button}>
            Compress Image
          </button>
        </form>
        
        {status && <p className={styles.status}>{status}</p>}
        
        {resultImage && (
          <div className={styles.result}>
            <h2>Compressed Image:</h2>
            <img src={resultImage} alt="Compressed" />
            <a 
              href={resultImage} 
              download="compressed-image.jpg"
              className={styles.download}
            >
              Download Image
            </a>
          </div>
        )}
      </main>
    </div>
  );
}