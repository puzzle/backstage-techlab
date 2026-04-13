import { Routes, Route } from 'react-router-dom'
import Home from './pages/Home'
{% if values.includeAuth %}
import Login from './pages/Login'
{% endif %}

function App() {
  return (
    <div className="app">
      <header>
        <h1>${{ values.name }}</h1>
        <p>${{ values.description }}</p>
      </header>
      <main>
        <Routes>
          <Route path="/" element={<Home />} />
          {% if values.includeAuth %}
          <Route path="/login" element={<Login />} />
          {% endif %}
        </Routes>
      </main>
    </div>
  )
}

export default App
