const express = require('express');
const app = express();
app.get('/health', (req, res) => res.status(200).json({ status: 'UP' }));
app.get('/', (req, res) => res.json({ message: 'Hello DevOps TP!' }));
module.exports = app;
if (require.main === module) app.listen(3000, () => console.log('Running on :3000'));
