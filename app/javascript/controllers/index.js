// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import HelloController from "./hello_controller"
application.register("hello", HelloController)

import CheckboxController from "./ui/checkbox_controller"
application.register("ui--checkbox", CheckboxController)

import UIDropdownController from './ui/dropdown_controller'
application.register("ui--dropdown", UIDropdownController)

import UIPopoverController from './ui/popover_controller'
application.register("ui--popover", UIPopoverController)

console.log("stimulus:register")