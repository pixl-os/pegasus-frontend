//
// Created by bkg2k on 03/11/2020.
//

#include "ProcessTree.h"
#include <unistd.h>
#include <proc/readproc.h>
#include <cstring>
#include <wait.h>
#include <utils/datetime/DateTime.h>

Array<int> ProcessTree::GetTree(int pid)
{
  if (pid < 0) pid = getpid();

  Array<int> result;

  proc_t proc;
  memset(&proc, 0, sizeof(proc));
  for(bool keepLooking = true; keepLooking;)
  {
    keepLooking = false;
    PROCTAB* procs = openproc(PROC_FILLSTAT);
    while(readproc(procs, &proc) != nullptr)
      if (((proc.ppid == pid) || result.Contains(proc.ppid)) && !result.Contains(proc.tgid))
      {
        result.Add(proc.tgid);
        keepLooking = true;
      }
    closeproc(procs);
  }

  result.Sort([](const int& a, const int& b) -> int { return a - b; });
  return result;
}

void ProcessTree::TerminateTree(Array<int>& processes, int millisecondTimeout)
{
  for(int i = processes.Count(); --i >= 0;)
    kill(processes[i], SIGTERM);

  if (!WaitTreeDeath(processes, millisecondTimeout))
    KillTree(processes);
}

void ProcessTree::KillTree(const Array<int>& processes)
{
  for(int i = processes.Count(); --i >= 0;)
    kill(processes[i], SIGKILL);
}

bool ProcessTree::WaitTreeDeath(Array<int>& pids, int millisecondTimeout)
{
  DateTime reference;

  int stat = 0;
  while((DateTime() - reference).TotalMilliseconds() < millisecondTimeout)
  {
    for(int i = pids.Count(); --i >= 0; )
      if (waitpid(pids[i], &stat, WNOHANG) == pids[i])
        pids.Delete(i);
    if (pids.Empty()) break;
    usleep(1000);
  }

  return pids.Empty();
}

