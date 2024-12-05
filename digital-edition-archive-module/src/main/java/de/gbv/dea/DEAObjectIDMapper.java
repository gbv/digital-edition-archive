package de.gbv.dea;

import de.gbv.dea.shelfmark.ShelfMarkMappingManager;
import org.mycore.datamodel.metadata.MCRObjectID;
import org.mycore.frontend.idmapper.MCRDefaultIDMapper;

import java.util.Optional;

public class DEAObjectIDMapper extends MCRDefaultIDMapper {

    @Override
    public Optional<MCRObjectID> mapMCRObjectID(String mcrid) {
        if(mcrid.contains(":")) {
            String project = mcrid.substring(0, mcrid.indexOf(":"));
            String shelfMark = mcrid.substring(mcrid.indexOf(":") + 1);
            Optional<MCRObjectID> objectID = ShelfMarkMappingManager.getMappedMycoreID(shelfMark, project)
                    .map(MCRObjectID::getInstance);

            if(objectID.isPresent()) {
                return objectID;
            }
        }


        return super.mapMCRObjectID(mcrid);
    }
}

