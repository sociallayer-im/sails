import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    connect() {
       
    }

    static targets = ["normal", "edit"];

    startEdit() {
        this.normalTarget.classList.toggle('hidden')
        this.editTarget.classList.toggle('hidden')
        this.element.style.backgroundColor = 'var(--checked-forground)'
        this.element.dataset.editable = true
    }

    cancelEdit() {
        this.normalTarget.classList.toggle('hidden')
        this.editTarget.classList.toggle('hidden')
        this.element.style.backgroundColor = 'var(--background)'
        const fields = this.element.querySelectorAll('*[data-field]')
        fields.forEach(element => {
            if (element.classList.contains('column-plant-text')) {
                element.innerHTML = element.dataset.value = element.dataset.initValue
            }
        })
        delete this.element.dataset.editable
    }

    confirmEdit () {
        let event = {}
        const fields = this.element.querySelectorAll('*[data-field]')
        fields.forEach(element => {
            const field = element.dataset.field
            const value = element.dataset.value
            element.dataset.initValue = element.dataset.value
            event[field] = value
        })
        this.cancelEdit()
        alert(`result=> ${JSON.stringify(event)}`)
    }
}