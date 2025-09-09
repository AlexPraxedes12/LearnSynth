export const API_BASE = process.env.NEXT_PUBLIC_API_BASE || 'https://learnsynth-api.fly.dev';

export async function uploadFile(formData, retries = 3) {
  for (let attempt = 0; attempt < retries; attempt++) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 30000);
    try {
      const response = await fetch(`${API_BASE}/upload-content`, {
        method: 'POST',
        body: formData,
        signal: controller.signal,
      });
      clearTimeout(timeoutId);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      return await response.json();
    } catch (err) {
      clearTimeout(timeoutId);
      if (attempt === retries - 1) {
        throw err;
      }
    }
  }
}
