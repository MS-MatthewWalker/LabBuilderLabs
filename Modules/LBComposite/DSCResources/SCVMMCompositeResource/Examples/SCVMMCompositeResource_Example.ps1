### Example configuration referencing the new composite resource
Configuration aaaaaa {
    
    Import-DscResource -ModuleName LBComposite

    Node localhost {

        SCVMMCompositeResource bbbbbb {
            property = value
        }

    }
}