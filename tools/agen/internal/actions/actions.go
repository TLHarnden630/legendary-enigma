package actions

import (
"os"
"path/filepath"
)

type Action struct {
ID    string
Label string
Cmd   string
}

func DetectActions(root string) ([]Action, error) {
var out []Action
if _, err := os.Stat(filepath.Join(root, "go.mod")); err == nil {
out = append(out, Action{ID: "go", Label: "go test", Cmd: "go test ./..."})
}
if _, err := os.Stat(filepath.Join(root, "package.json")); err == nil {
out = append(out, Action{ID: "npm", Label: "npm ci && npm test", Cmd: "npm ci && npm test"})
}
return out, nil
}
