import { useCallback, useEffect, useState } from 'react'
import type { FormEvent } from 'react'
import './App.css'

type Status = 'TODO' | 'IN_PROGRESS' | 'DONE'
type Task = { id: string; title: string; description: string | null; status: Status }

const apiUrl = import.meta.env.VITE_API_URL ?? 'http://localhost:3000'
const labels: Record<Status, string> = { TODO: 'À faire', IN_PROGRESS: 'En cours', DONE: 'Terminée' }

function App() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadTasks = useCallback(async () => {
    setLoading(true); setError(null)
    try {
      const response = await fetch(`${apiUrl}/tasks`)
      if (!response.ok) throw new Error()
      setTasks(await response.json())
    } catch { setError(`L’API est inaccessible à l’adresse ${apiUrl}.`) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { void loadTasks() }, [loadTasks])

  async function createTask(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!title.trim()) return
    setSubmitting(true); setError(null)
    try {
      const response = await fetch(`${apiUrl}/tasks`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ title: title.trim(), ...(description.trim() ? { description: description.trim() } : {}) }) })
      if (!response.ok) throw new Error()
      setTitle(''); setDescription(''); await loadTasks()
    } catch { setError('La tâche n’a pas pu être créée.') }
    finally { setSubmitting(false) }
  }

  async function updateStatus(id: string, status: Status) {
    setError(null)
    try {
      const response = await fetch(`${apiUrl}/tasks/${id}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ status }) })
      if (!response.ok) throw new Error()
      await loadTasks()
    } catch { setError('Le statut n’a pas pu être mis à jour.') }
  }

  async function deleteTask(id: string) {
    setError(null)
    try {
      const response = await fetch(`${apiUrl}/tasks/${id}`, { method: 'DELETE' })
      if (!response.ok) throw new Error()
      await loadTasks()
    } catch { setError('La tâche n’a pas pu être supprimée.') }
  }

  return <main className="app-shell">
    <header className="hero"><p className="eyebrow">MINI TASK MANAGER</p><h1>Mes tâches</h1><p className="intro">Interface de démonstration de l’API NestJS.</p></header>
    <section className="panel"><h2>Nouvelle tâche</h2><form className="task-form" onSubmit={createTask}>
      <label>Titre<input value={title} onChange={(e) => setTitle(e.target.value)} maxLength={160} required /></label>
      <label>Description <span>(facultative)</span><input value={description} onChange={(e) => setDescription(e.target.value)} maxLength={2000} /></label>
      <button type="submit" disabled={submitting}>{submitting ? 'Création…' : 'Ajouter'}</button>
    </form></section>
    <section className="panel"><div className="section-heading"><h2>Tâches</h2><button className="secondary" type="button" onClick={() => void loadTasks()}>Actualiser</button></div>
      {error && <p className="notice error" role="alert">{error}</p>}
      {loading ? <p className="empty">Chargement…</p> : tasks.length === 0 ? <p className="empty">Aucune tâche pour le moment.</p> : <ul className="task-list">{tasks.map((task) => <li key={task.id} className="task-card"><div><h3>{task.title}</h3>{task.description && <p>{task.description}</p>}</div><div className="task-actions"><select aria-label={`Statut de ${task.title}`} value={task.status} onChange={(e) => void updateStatus(task.id, e.target.value as Status)}>{Object.entries(labels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select><button className="danger" type="button" onClick={() => void deleteTask(task.id)}>Supprimer</button></div></li>)}</ul>}
    </section>
  </main>
}

export default App
