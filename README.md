# acasapulla.github.io

Portfolio site for Anthony Casapulla — cybersecurity & technology risk.
Live at **https://acasapulla.github.io**. Built with Jekyll; GitHub Pages
rebuilds the site automatically on every push to `main`.

## Add a project

1. Copy the template (the file name becomes the URL, `/projects/<name>/`):
   ```bash
   cp _projects/example-project.md _projects/my-project-name.md
   ```
2. Open the new file and **delete the `published: false` line**.
3. Fill in the fields at the top:
   | Field | Required | What it does |
   |---|---|---|
   | `title` | yes | Project name |
   | `date` | yes | `YYYY-MM-DD`; newest projects show first |
   | `description` | yes | 2–3 sentences shown on the card and in link previews (LinkedIn, etc.) |
   | `tags` | no | e.g. `[Risk Assessment, NIST CSF]` |
   | `featured` | no | `true` pins it to the top |
   | `repo` | no | Link to a GitHub repo → "View code" button |
   | `report` | no | e.g. `/assets/files/report.pdf` → "Read the report" button |
4. Write the Overview / What I Did / Results & Takeaways sections in Markdown.
   Images go in `assets/img/` (create the folder the first time: `mkdir -p assets/img`)
   and are used like `![Diagram](/assets/img/diagram.png)`.
5. Publish:
   ```bash
   git add .
   git commit -m "Add project: my project name"
   git push
   ```
   The site updates in about a minute.

## Edit your info

Name, tagline, LinkedIn, GitHub, résumé and (optional) email live at the top of
`_config.yml`. The intro and About text are in `index.html`.

### Adding your résumé

1. `mkdir -p assets/files` and save the PDF as `assets/files/resume.pdf`.
2. In `_config.yml`, remove the `# ` in front of `resume: /assets/files/resume.pdf`.
3. Commit and push. "Résumé" links then appear in the header, intro and footer.

> **Heads-up:** anything under `assets/` is public, even if no page links to it.
> Use a version of your résumé without your phone number or home address.

## Preview locally (optional)

Needs Homebrew Ruby 3.3 (`brew install ruby@3.3`). Add it to your PATH once by
putting this line in `~/.zshrc`:

```bash
export PATH="/opt/homebrew/opt/ruby@3.3/bin:$PATH"
```

Then:

```bash
bundle install                 # first time only
bundle exec jekyll serve       # open http://localhost:4000
```

## Run the tests

```bash
bash scripts/test_site.sh      # builds the site and checks the output → ALL PASS
```

Test-only sample projects live in `test/fixtures/_projects/` and never appear on
the live site.
