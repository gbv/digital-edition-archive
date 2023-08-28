package de.gbv.dea;

import jakarta.servlet.http.HttpServletRequest;
import org.mycore.viewer.configuration.MCRViewerConfiguration;
import org.mycore.viewer.configuration.MCRViewerDefaultConfigurationStrategy;

public class ViewerConfigurationStrategy extends MCRViewerDefaultConfigurationStrategy {

    @Override
    protected MCRViewerConfiguration getMETS(HttpServletRequest request) {
        MCRViewerConfiguration mets = super.getMETS(request);
        mets.setProperty("text.showOnStart", "transcription");
        mets.setProperty("canvas.overview.enabled", false);
        return mets;
    }
}
