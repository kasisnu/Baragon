package com.hubspot.baragon.service.worker;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Optional;
import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hubspot.baragon.data.BaragonStateDatastore;

@Singleton
public class BaragonBackgroundStateUpdatingWorker implements Runnable {
  private static final Logger LOG = LoggerFactory.getLogger(BaragonBackgroundStateUpdatingWorker.class);

  private final BaragonStateDatastore stateDatastore;
  private Optional<Integer> lastUpdateId;

  @Inject
  public BaragonBackgroundStateUpdatingWorker(BaragonStateDatastore stateDatastore) {
    this.stateDatastore = stateDatastore;
    this.lastUpdateId = Optional.absent();
  }

  @Override
  public void run() {
    try {
      LOG.trace("Updating state node in ZK...");

      final long start = System.currentTimeMillis();

      final Optional<Integer> currentUpdateId = stateDatastore.getStateVersion();

      if (!currentUpdateId.equals(lastUpdateId)) {
        stateDatastore.updateStateNode();
        LOG.debug("Updated state node in ZK in {}ms (version: {} -> {})", System.currentTimeMillis() - start, lastUpdateId, currentUpdateId);
        lastUpdateId = currentUpdateId;
      } else {
        LOG.trace("State node unchanged in {}ms (version: {})", System.currentTimeMillis() - start, lastUpdateId);
      }
    } catch (Exception e) {
      LOG.error("Caught exception during state node update", e);
    }
  }
}
