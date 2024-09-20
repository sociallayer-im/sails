import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {}

    editConfirm() {
        const value = this.element.querySelector('input').value
        this.element.innerHTML = value
    }
  
    edit() {
        const input = document.createElement('input')
        input.value = this.element.dataset.value
        input.style.width = '100%'
        input.style.height = '100%'
        input.style.display = 'block'
        input.addEventListener('click', (e) => {e.stopPropagation()})
        input.addEventListener('blur', (e) => {
            this.element.dataset.value = e.target.value.trim()
            this.editConfirm()
        })
        this.element.innerHTML = ''
        this.element.appendChild(input)
        input.focus()
    }
    
  }