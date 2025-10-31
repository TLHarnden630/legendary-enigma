package run

import (
"os/exec"
)

func RunCommand(cmd string) error {
// minimal sync runner
c := exec.Command("sh", "-lc", cmd)
return c.Run()
}
