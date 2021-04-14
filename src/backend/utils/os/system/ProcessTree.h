//
// Created by bkg2k on 03/11/2020.
//
#pragma once

#include <utils/storage/Array.h>

class ProcessTree
{
  public:
    static void TerminateAll(int millisesonds)
    {
      Array<int> processes = GetTree(-1);
      TerminateTree(processes, millisesonds);
    }

    static Array<int> GetTree(int pid);

    static void TerminateTree(Array<int>& processes, int millisecondTimeout) ;

    static void KillTree(const Array<int>& processes) ;

    static bool WaitTreeDeath(Array<int>& pids, int millisecondTimeout);
};
