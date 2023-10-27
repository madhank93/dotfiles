!`::{
  OldClass := WinGetClass("A")
  ActiveProcessName := WinGetProcessName("A")
  WinClassCount := WinGetCount("ahk_exe" ActiveProcessName)
  IF WinClassCount = 1
      Return
  loop 2 {
    WinMoveBottom("A")
    WinActivate("ahk_exe" ActiveProcessName)
    NewClass := WinGetClass("A")
    if (OldClass != "CabinetWClass" or NewClass = "CabinetWClass")
      break
  }
}