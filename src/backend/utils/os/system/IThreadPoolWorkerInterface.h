#pragma once

template<class FeedObject, class ResultObject> class IThreadPoolWorkerInterface
{
  public:
    /*!
     * @brief A new job has started
     * @param feed Feed object to process
     */
    virtual void ThreadPoolJobStart(FeedObject& feed) { (void)feed; }

    /*!
     * @brief The main runner. Implement here the task to process a feed object
     * @param feed Feed object to process
     * @return Result Object
     */
    virtual ResultObject ThreadPoolRunJob(FeedObject& feed) = 0;

    /*!
     * @brief A job has completed
     * @param feed Feed object completed
     * @param remainingJobs Jobs still in queue
     */
    virtual void ThreadPoolJobCompleted(FeedObject& feed, int remainingJobs) { (void)feed; (void)remainingJobs; }

    /*!
     * @brief Called asap by the main thread when a job complete, regarding the tick duration
     * @param completed Currently completed jobs count
     * @param total Total jobs
     */
    virtual void ThreadPoolTick(int completed, int total) { (void)completed; (void)total; };
};