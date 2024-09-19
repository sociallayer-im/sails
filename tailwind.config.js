const defaultTheme = require("tailwindcss/defaultTheme");
const shadcnConfig = require("./config/shadcn.tailwind.js");

module.exports = {
  content: [
    "./public/*.html",
    './app/views/**/*.html.erb',
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
    './app/assets/stylesheets/**/*.css',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    // require('daisyui'),
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
  ...shadcnConfig,
};
