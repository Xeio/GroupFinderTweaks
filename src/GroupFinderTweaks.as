import com.GameInterface.GroupFinder;
import mx.utils.Delegate;
import com.Utils.Archive;
import com.Utils.LDBFormat;

class GroupFinderTweaks
{    
	private var m_swfRoot: MovieClip;
    
    var m_customEntries:Array;
    var m_baseGetSelectedEntries:Function, m_baseLayoutEntries:Function;
    
    var m_lastPlayfieldName, m_lastPlayfieldId, m_lastPlayfieldImage;
    var m_lastSelectedEntries;
    
    var LAST_PLAYFIELD_NAME = "LastPlayfieldName";
    var LAST_PLAYFIELD_ID = "LastPlayfieldID";
    var LAST_PLAYFIELD_IMAGE = "LastPlayfieldImage";
		
	public static function main(swfRoot:MovieClip):Void 
	{
		var groupFinderTweaks = new GroupFinderTweaks(swfRoot);
		
		swfRoot.onLoad = function() { groupFinderTweaks.OnLoad(); };
		swfRoot.OnUnload =  function() { groupFinderTweaks.OnUnload(); };
		swfRoot.OnModuleActivated = function(config:Archive) { groupFinderTweaks.Activate(config); };
		swfRoot.OnModuleDeactivated = function() { return groupFinderTweaks.Deactivate(); };
	}
	
    public function GroupFinderTweaks(swfRoot: MovieClip) 
    {
		m_swfRoot = swfRoot;
    }
	
	public function OnLoad()
	{
        m_lastSelectedEntries = [];
        m_customEntries = [];
		setTimeout(Delegate.create(this, SetupUI), 50);
	}
    
    private function SetupUI()
    {
        var groupFinderContent = _root.groupfinder.m_Window.m_Content;
        if (!groupFinderContent)
        {
            setTimeout(Delegate.create(this, SetupUI), 50);
            return;
        }
        var groupFinderScrollPanel = groupFinderContent.m_ScrollPanel;
        var m_ListContent = groupFinderScrollPanel.m_ListContent;
        
        m_baseGetSelectedEntries = Delegate.create(groupFinderScrollPanel, groupFinderScrollPanel.GetSelectedEntries);
        groupFinderScrollPanel.GetSelectedEntries = Delegate.create(this, CustomGetSelectedEntries);
        
        m_baseLayoutEntries = Delegate.create(groupFinderScrollPanel, groupFinderScrollPanel.LayoutEntries);
        groupFinderScrollPanel.LayoutEntries = Delegate.create(this, CustomLayoutEntries);
        
        groupFinderContent.m_SignUpLeaveButton.addEventListener("click", this, "SignUpLeaveClickHandler");
        
        if (m_lastPlayfieldId)
        {
            //Add last remembered queue
            var newEntry = m_ListContent.attachMovie("PlayfieldEntry", m_ListContent.getUID(), m_ListContent.getNextHighestDepth());
            newEntry.SetData("Last Queued: " + m_lastPlayfieldName, m_lastPlayfieldId, 0 /*difficulty*/, m_lastPlayfieldImage, [], 0, false);
            newEntry.SignalEntrySizeChanged.Connect(groupFinderScrollPanel.LayoutEntries, groupFinderScrollPanel);
            newEntry.SignalEntryToggled.Connect(groupFinderScrollPanel.SlotEntryToggled, groupFinderScrollPanel);
            newEntry.SignalEntryFocused.Connect(groupFinderScrollPanel.SlotEntryFocused, groupFinderScrollPanel);
            
            for (var i in groupFinderScrollPanel.m_PlayfieldEntries)
            {
                var baseEntry = groupFinderScrollPanel.m_PlayfieldEntries[i];
            
                baseEntry.SignalEntrySizeChanged.Connect(CustomLayoutEntries, this);
            }
            
            m_customEntries.unshift(newEntry);
        }
        
        var eliteDungeons = groupFinderScrollPanel.GetEliteDungeons();
        AddMaxEligable("Dungeon ", eliteDungeons);
        
        var soloScenarios = groupFinderScrollPanel.GetSoloScenarios();
        AddMaxEligable("Solo Scenario ", soloScenarios);
        
        var duoScenarios = groupFinderScrollPanel.GetDuoScenarios();
        AddMaxEligable("Duo Scenario ", duoScenarios);
        
        CustomLayoutEntries();
    }
    
    private function CustomGetSelectedEntries()
    {
        var selectedEntries = m_baseGetSelectedEntries();
        
        for (var i in m_customEntries)
        {
            m_customEntries[i].FillSelectedEntriesArray(selectedEntries);
        }
        
        return selectedEntries;
    }
    
    private function AddMaxEligable(namePrefix, playfieldEntries)
    {
        var groupFinderScrollPanel = _root.groupfinder.m_Window.m_Content.m_ScrollPanel;
        var m_ListContent = groupFinderScrollPanel.m_ListContent;
        
        var maxPlayfieldLevel;
        for (var i = 0; i < playfieldEntries.length; i++)
        {
            var missingReqs = GroupFinder.CheckQueueRequirements(playfieldEntries[i].queueId, true);
            if (missingReqs == "")
            {
                maxPlayfieldLevel = playfieldEntries[i];
            }
        }
        
        var newEntry = m_ListContent.attachMovie("PlayfieldEntry", m_ListContent.getUID(), m_ListContent.getNextHighestDepth());
        newEntry.SetData(namePrefix + maxPlayfieldLevel.playfieldName, maxPlayfieldLevel.queueId, maxPlayfieldLevel.difficulty , maxPlayfieldLevel.image, maxPlayfieldLevel.subEntries, 0, false);
		newEntry.SignalEntrySizeChanged.Connect(groupFinderScrollPanel.LayoutEntries, groupFinderScrollPanel);
		newEntry.SignalEntryToggled.Connect(groupFinderScrollPanel.SlotEntryToggled, groupFinderScrollPanel);
		newEntry.SignalEntryFocused.Connect(groupFinderScrollPanel.SlotEntryFocused, groupFinderScrollPanel);
        
        for (var i in groupFinderScrollPanel.m_PlayfieldEntries)
        {
            var baseEntry = groupFinderScrollPanel.m_PlayfieldEntries[i];
        
            baseEntry.SignalEntrySizeChanged.Connect(CustomLayoutEntries, this);
        }
        
        m_customEntries.unshift(newEntry);
    }
    
    private function CustomLayoutEntries()
    {        
        m_baseLayoutEntries();
        
        var groupFinderScrollPanel = _root.groupfinder.m_Window.m_Content.m_ScrollPanel;
        
        var y = 0;
        
        for (var i in m_customEntries)
        {
            m_customEntries[i]._y = y;
        
            y += m_customEntries[i].GetFullHeight() + 1;
        }
        
        for (var i in groupFinderScrollPanel.m_PlayfieldEntries)
        {
            groupFinderScrollPanel.m_PlayfieldEntries[i]._y += y;
        }

        groupFinderScrollPanel.ContentSizeUpdated();
    }
    
    private function SignUpLeaveClickHandler()
    {
        var groupFinderScrollPanel = _root.groupfinder.m_Window.m_Content.m_ScrollPanel;
        groupFinderScrollPanel.DisableAllEntries(false, "");
        
        var selectedEntries:Array = CustomGetSelectedEntries();
        
        for (var i in selectedEntries)
        {
            var playfield = selectedEntries[i];
            
            if (playfield.m_Id > 0)
            {
                m_lastPlayfieldId = playfield.m_Id;
                m_lastPlayfieldName = playfield.m_Name.text;
                m_lastPlayfieldImage = playfield.m_Image;
                
                break;
            }
        }
        
        groupFinderScrollPanel.DisableAllEntries(true, LDBFormat.LDBGetText("GroupSearchGUI", "JoiningQueue"));
    }
	
	public function OnUnload()
	{
        m_customEntries = [];
        _root.groupfinder.m_Window.m_Content.m_ScrollPanel.GetSelectedEntries = m_baseGetSelectedEntries;
        _root.groupfinder.m_Window.m_Content.m_ScrollPanel.LayoutEntries = m_baseLayoutEntries;
	}
	
	public function Activate(config: Archive)
	{
        m_lastPlayfieldName = config.FindEntry(LAST_PLAYFIELD_NAME);
        m_lastPlayfieldId = config.FindEntry(LAST_PLAYFIELD_ID);
        m_lastPlayfieldImage = config.FindEntry(LAST_PLAYFIELD_IMAGE);
	}
	
	public function Deactivate(): Archive
	{
		var archive: Archive = new Archive();
        if (m_lastPlayfieldName)
        {
            archive.AddEntry(LAST_PLAYFIELD_NAME, m_lastPlayfieldName);
            archive.AddEntry(LAST_PLAYFIELD_ID, m_lastPlayfieldId);
            archive.AddEntry(LAST_PLAYFIELD_IMAGE, m_lastPlayfieldImage);
        }
		return archive;
	}
}