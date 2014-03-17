program_name='drag-and-drop-demo'

#include 'amx-modero-api'
#include 'amx-modero-control'



define_device

dvTp = 10001:1:00
touchTracker = 33001:1:0




define_type

define_constant

integer NUM_OF_DRAGGABLE_ITEMS = 4
integer NUM_OF_DROP_AREAS = 2

integer BTN_ADR_CDE_DROP_AREA_1 = 1
integer BTN_ADR_CDE_DROP_AREA_2 = 2

integer BTN_ARD_CDE_DROP_AREAS[NUM_OF_DROP_AREAS] = 
{
	BTN_ADR_CDE_DROP_AREA_1,
	BTN_ADR_CDE_DROP_AREA_2
}

integer BTN_ADR_CDE_DRAGGABLE_ITEM_1 = 11
integer BTN_ADR_CDE_DRAGGABLE_ITEM_2 = 12
integer BTN_ADR_CDE_DRAGGABLE_ITEM_3 = 13
integer BTN_ADR_CDE_DRAGGABLE_ITEM_4 = 14


integer BTN_ADR_CDE_DRAGGABLE_ITEMS[NUM_OF_DRAGGABLE_ITEMS] =
{
	BTN_ADR_CDE_DRAGGABLE_ITEM_1,
	BTN_ADR_CDE_DRAGGABLE_ITEM_2,
	BTN_ADR_CDE_DRAGGABLE_ITEM_3,
	BTN_ADR_CDE_DRAGGABLE_ITEM_4
}

char POPUP_NAMES_DRAGGABLE_ITEMS[NUM_OF_DRAGGABLE_ITEMS][30] = 
{
	'draggable-item-1',
	'draggable-item-2',
	'draggable-item-3',
	'draggable-item-4'
}

char BITMAP_NAME_NO_VIDEO_ICON[] = 'icon-no-video.png'


char DELIM_HEADER[] = '-'
char DELIM_PARAM[] = ','


define_variable

char draggableItemBitmapNames[NUM_OF_DRAGGABLE_ITEMS][30]


define_module 'drag-and-drop' dragAndDropMod (touchTracker, dvTp)



#define INCLUDE_MODERO_NOTIFY_BUTTON_BITMAP_NAME
define_function moderoNotifyButtonBitmapName (dev panel, integer btnAdrCde, integer nbtnState, char bitmapName[])
{
	// panel is the touch panel
	// btnAdrCde is the button address code
	// btnState is the button state
	// bitmapName is the name of the image assigned to the button
	
	switch (btnAdrCde)
	{
		case BTN_ADR_CDE_DRAGGABLE_ITEM_1:	draggableItemBitmapNames[1] = bitmapName
		case BTN_ADR_CDE_DRAGGABLE_ITEM_2:	draggableItemBitmapNames[2] = bitmapName
		case BTN_ADR_CDE_DRAGGABLE_ITEM_3:	draggableItemBitmapNames[3] = bitmapName
		case BTN_ADR_CDE_DRAGGABLE_ITEM_4:	draggableItemBitmapNames[4] = bitmapName
	}
}


define_event

data_event[dvTp]
{
	online:
	{
		integer i
		
		moderoSetButtonBitmap (dvTp, BTN_ADR_CDE_DROP_AREA_1, MODERO_BUTTON_STATE_OFF, BITMAP_NAME_NO_VIDEO_ICON)
		moderoSetButtonBitmap (dvTp, BTN_ADR_CDE_DROP_AREA_2, MODERO_BUTTON_STATE_OFF, BITMAP_NAME_NO_VIDEO_ICON)
		
		for (i = 1; i <= NUM_OF_DRAGGABLE_ITEMS; i++)
		{
			moderoRequestButtonBitmapName (dvTp, BTN_ADR_CDE_DRAGGABLE_ITEMS[i], MODERO_BUTTON_STATE_OFF)
			moderoDisablePopup (dvTp, POPUP_NAMES_DRAGGABLE_ITEMS[i])
			moderoEnablePopup (dvTp, POPUP_NAMES_DRAGGABLE_ITEMS[i])
		}
	}
}


data_event [touchTracker]
{
	online:
	{
		// Define drop areas
		//send_command touchTracker, 'DEFINE_DROP_AREA-<id>,<left>,<top>,<width>,<height>'
		send_command touchTracker, 'DEFINE_DROP_AREA-1,175,135,430,270'
		send_command touchTracker, 'DEFINE_DROP_AREA-2,676,135,430,270'
		
		// Define drop items
		//send_command touchTracker, 'DEFINE_DROP_ITEM-<id>,<left>,<top>,<width>,<height>'
		send_command touchTracker, 'DEFINE_DRAG_ITEM-1,254,625,160,118'
		send_command touchTracker, 'DEFINE_DRAG_ITEM-2,458,625,160,118'
		send_command touchTracker, 'DEFINE_DRAG_ITEM-3,662,625,160,118'
		send_command touchTracker, 'DEFINE_DRAG_ITEM-4,866,625,160,118'
	}
	
	string:
	{
		stack_var char header[50]
		
		header = remove_string (data.text,DELIM_HEADER,1)
		
		switch (header)
		{
			case 'DRAG_ITEM_SELECTED-': {}
			case 'DRAG_ITEM_DESELECTED-':
			{
				stack_var integer idDragItem
				
				idDragItem = atoi(data.text)
				
				moderoDisablePopup (dvTp, POPUP_NAMES_DRAGGABLE_ITEMS[idDragItem])
				moderoEnablePopup (dvTp, POPUP_NAMES_DRAGGABLE_ITEMS[idDragItem])
			}
			case 'DRAG_ITEM_ENTER_DROP_AREA-': {}
			case 'DRAG_ITEM_EXIT_DROP_AREA-': {}
			case 'DRAG_ITEM_DROPPED_ON_DROP_AREA-':
			{
				stack_var integer idDragItem
				stack_var integer idDropArea
				
				idDragItem = atoi(remove_string(data.text,DELIM_PARAM,1))
				idDropArea = atoi(data.text)
				
				moderoSetButtonBitmap (dvTp, BTN_ARD_CDE_DROP_AREAS[idDropArea], MODERO_BUTTON_STATE_OFF, draggableItemBitmapNames[idDragItem])
				moderoDisablePopup (dvTp, POPUP_NAMES_DRAGGABLE_ITEMS[idDragItem])
				moderoEnablePopup (dvTp, POPUP_NAMES_DRAGGABLE_ITEMS[idDragItem])
			}
		}
	}
}



#include 'amx-modero-listener'
