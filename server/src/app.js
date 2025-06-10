const mixRoutes = require('./routes/mixRoutes');
const profileRoutes = require('./routes/profileRoutes');

app.use('/api/mixes', mixRoutes);
app.use('/api/profiles', profileRoutes); 