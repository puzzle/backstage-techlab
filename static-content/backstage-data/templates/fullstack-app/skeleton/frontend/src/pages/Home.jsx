import { useState, useEffect } from 'react'
import axios from 'axios'

function Home() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    axios.get('/api/health')
      .then(response => {
        setData(response.data)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching data:', error)
        setLoading(false)
      })
  }, [])

  if (loading) return <div>Loading...</div>

  return (
    <div>
      <h2>Welcome to ${{ values.name }}</h2>
      <p>API Status: {data?.status || 'Unknown'}</p>
      <p>Database: ${{ values.database }}</p>
      {% if values.includeAuth %}
      <p>Authentication: Enabled</p>
      {% endif %}
    </div>
  )
}

export default Home
