import { useState, useEffect } from 'react'
import axios from 'axios'

function Login() {
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
      <h2>Login</h2>
      <p>Authentication: Enabled</p>
    </div>
  )
}

export default Login
