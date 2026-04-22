import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
{% if values.includeAuth %}
import authRoutes from './routes/auth.js'
{% endif %}
import healthRoutes from './routes/health.js'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3001

app.use(cors())
app.use(express.json())

// Routes
app.use('/api/health', healthRoutes)
{% if values.includeAuth %}
app.use('/api/auth', authRoutes)
{% endif %}

app.listen(PORT, () => {
  console.log(`${{ values.name }} backend running on port ${PORT}`)
  console.log(`Database: ${{ values.database }}`)
  {% if values.includeAuth %}
  console.log(`Authentication: Enabled`)
  {% endif %}
})

export default app
