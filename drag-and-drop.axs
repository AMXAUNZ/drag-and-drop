module_name='drag-and-drop' (dev virtual, dev panel)

#include 'amx-modero-control'
#include 'touch-tracker'


define_constant

// CMD/STR Delimeters
char DELIM_HEADER[] = '-'
char DELIM_PARAM[] = ','

/*
 * Command Headers
 */
char CMD_HEADER_DEFINE_DRAG_ITEM[] = 'DEFINE_DRAG_ITEM-'
// CMD Syntax:
//    'DEFINE_DROP_ITEM-<id>,<left>,<top>,<width>,<height>'
// Example:
//    'DEFINE_DRAG_ITEM-1,254,625,160,118'
char CMD_HEADER_DEFINE_DROP_AREA[] = 'DEFINE_DROP_AREA-'
// CMD Syntax:
//    'DEFINE_DROP_AREA-<id>,<left>,<top>,<width>,<height>'
// Example:
//    'DEFINE_DROP_AREA-1,254,625,160,118'

/*
 * String Response Headers
 */
char STR_RESP_HEADER_DRAG_ITEM_SELECTED[]             = 'DRAG_ITEM_SELECTED-'
// CMD Syntax:
//    'DRAG_ITEM_SELECTED-<id>'
// Example:
//    'DRAG_ITEM_SELECTED-1'
char STR_RESP_HEADER_DRAG_ITEM_DESELECTED[]           = 'DRAG_ITEM_DESELECTED-'
// CMD Syntax:
//    'DRAG_ITEM_DESELECTED-<id>'
// Example:
//    'DRAG_ITEM_DESELECTED-1'
char STR_RESP_HEADER_DRAG_ITEM_ENTER_DROP_AREA[]      = 'DRAG_ITEM_ENTER_DROP_AREA-'
// CMD Syntax:
//    'DRAG_ITEM_ENTER_DROP_AREA-<drag_item_id>,<drop_area_id>'
// Example:
//    'DRAG_ITEM_ENTER_DROP_AREA-1,1'
char STR_RESP_HEADER_DRAG_ITEM_EXIT_DROP_AREA[]       = 'DRAG_ITEM_EXIT_DROP_AREA-'
// CMD Syntax:
//    'DRAG_ITEM_EXIT_DROP_AREA-<drag_item_id>,<drop_area_id>'
// Example:
//    'DRAG_ITEM_EXIT_DROP_AREA-1,1'
char STR_RESP_HEADER_DRAG_ITEM_DROPPED_ON_DROP_AREA[] = 'DRAG_ITEM_DROPPED_ON_DROP_AREA-'
// CMD Syntax:
//    'DRAG_ITEM_DROPPED_ON_DROP_AREA-<drag_item_id>,<drop_area_id>'
// Example:
//    'DRAG_ITEM_DROPPED_ON_DROP_AREA-1,1'

/*
 * Maxiumum values
 */

integer MAX_DROP_AREAS = 50
integer MAX_DRAG_AREAS = 50
integer MAX_AREA_NAME_LENGTH = 50


define_type

structure _bounds
{
	integer left
	integer top
	integer width
	integer height
}

structure _area
{
	integer id
	_bounds bounds
}


define_variable

// Listener DEV array for amx-modero-listener
dev dvPanelsCoordinateTracking[1]

_area dropAreas[MAX_DROP_AREAS]
_area dragAreas[MAX_DRAG_AREAS]
integer selectedDragArea[MAXIMUM_TOUCH_POINTS]
char intersectStatus[MAX_DRAG_AREAS][MAX_DROP_AREAS] 


define_start

// Populate listener DEV array for amx-modero-listener
dvPanelsCoordinateTracking[1] = panel
set_length_array (dvPanelsCoordinateTracking,1)
rebuild_event()


define_function copyRectangle (_bounds boundsCopyTo, _bounds boundsCopyFrom)
{
	boundsCopyTo.height = boundsCopyFrom.height
	boundsCopyTo.left = boundsCopyFrom.left
	boundsCopyTo.top = boundsCopyFrom.top
	boundsCopyTo.width = boundsCopyFrom.width
}

define_function updateArea (_area area, integer id, _bounds bounds)
{
	area.id = id
	copyRectangle (area.bounds, bounds)
}


define_function addDragArea (integer id, _bounds bounds)
{
	// #1) check to see (a) that the id is not zero - ignore if it is and exit.
	// #2) check if the array is empty - if it is add the item to the first index and exit.
	// #3) check to see if the id for the item is already in the array - if the id exists just update the _bounds info at that location and exit
	// #4) check if the array is full - if it is not, increase the size of the list (aka, length of the array), add the item to the new end of the list and exit.
	
	stack_var integer i
	
	if (id == 0)
		return
	
	if (length_array(dragAreas) == 0)
	{
		set_length_array (dragAreas, 1)
		updateArea (dragAreas[1], id, bounds)
		return
	}
	
	for (i = 1; i <= length_array(dragAreas); i++)
	{
		if (dragAreas[i].id == id)
		{
			updateArea (dragAreas[i], id, bounds)
			return
		}
	}
	
	// check that the array is not full
	if (length_array(dragAreas) < max_length_array(dragAreas))
	{
		set_length_array (dragAreas, (length_array(dragAreas)+1))
		updateArea (dragAreas[length_array(dragAreas)], id, bounds)
		return
	}
}


define_function addDropArea (integer id, _bounds bounds)
{
	// #1) check to see (a) that the id is not zero - ignore if it is and exit.
	// #2) check if the array is empty - if it is add the item to the first index and exit.
	// #3) check to see if the id for the item is already in the array - if the id exists just update the _bounds info at that location and exit
	// #4) check if the array is full - if it is not, increase the size of the list (aka, length of the array), add the item to the new end of the list and exit.
	
	stack_var integer i
	
	if (id == 0)
		return
	
	if (length_array(dropAreas) == 0)
	{
		set_length_array (dropAreas, 1)
		updateArea (dropAreas[1], id, bounds)
		return
	}
	
	for (i = 1; i <= length_array(dropAreas); i++)
	{
		if (dropAreas[i].id == id)
		{
			updateArea (dropAreas[i], id, bounds)
			return
		}
	}
	
	// check that the array is not full
	if (i <= max_length_array(dropAreas))
	{
		set_length_array (dropAreas, i)
		updateArea (dropAreas[i], id, bounds)
		return
	}
}

// function to check if an X,Y coordinate is within the bounds of an area
define_function integer isCoordWithinBounds (integer xCoord, integer yCoord, _area area)
{
	if ((xCoord < area.bounds.left) or (xCoord > (area.bounds.left+area.bounds.width)))
		return false
	
	if ((yCoord < area.bounds.top) or (yCoord > (area.bounds.top+area.bounds.height)))
		return false
	
	return true
}


/*
 * Override the notify callback functions from amx-modero-listener.
 */

#define INCLUDE_MODERO_NOTIFY_TOUCH_COORDINATES_PRESS
// Note: This will get triggered BEFORE a push event handler in a button_event
// Note: If push/release coordinate reporting is enabled a push anywhere on the panel will trigger this function
define_function moderoNotifyTouchCoordinatesPress (dev panel, integer nX, integer nY)
{
	// panel is the touch panel
	// nX is the X coordinate
	// nY is the Y Coordinate
	
	stack_var integer idTouchPoint
	stack_var integer i
	
	idTouchPoint = getNextAvailableTouchPointID ()
	setTouchPointCoords (idTouchPoint, nX, nY)
	setTouchPointActive (idTouchPoint)
	
	for (i = 1; i <= length_array(dragAreas); i++)
	{
		if (isCoordWithinBounds(nX, nY, dragAreas[i]))
		{
			selectedDragArea[idTouchPoint] = i
			send_string virtual, "STR_RESP_HEADER_DRAG_ITEM_SELECTED,itoa(dragAreas[i].id)"
		}
	}
}


#define INCLUDE_MODERO_NOTIFY_TOUCH_COORDINATES_MOVE
// Note: This will get triggered BEFORE a push event handler in a button_event
// Note: If push/release coordinate reporting is enabled a movement in user touch anywhere on the panel will trigger this function
define_function moderoNotifyTouchCoordinatesMove (dev panel, integer nX, integer nY)
{
	// panel is the touch panel
	// nX is the X coordinate
	// nY is the Y Coordinate
	
	stack_var integer idTouchPoint
	stack_var Point p
	stack_var integer i
	
	setPointCoords (p, nX, nY)
	idTouchPoint =  getClosestTouchPoint(p)
	
	if (idTouchPoint)	// check to see that there is a touch point being tracked (mouse movements over VNC will trigger a move even though there has been no push
	{
		setTouchPointCoords (idTouchPoint, nX, nY)
		
		// intersectStatus
		// selectedDragArea[idTouchPoint] - contains the index of the selected drag area in the dragAreas array
		
		if (selectedDragArea[idTouchPoint])
		{
			for (i=1; i<=max_length_array(dropAreas); i++)
			{
				if( isCoordWithinBounds(nX,nY,dropAreas[i]) )
				{
					if (!intersectStatus[selectedDragArea[idTouchPoint]][i])
					{
						intersectStatus[selectedDragArea[idTouchPoint]][i] = true
						send_string virtual, "STR_RESP_HEADER_DRAG_ITEM_ENTER_DROP_AREA,itoa(dragAreas[selectedDragArea[idTouchPoint]].id),DELIM_PARAM,itoa(dragAreas[i].id)"
					}
				}
				else
				{
					if (intersectStatus[selectedDragArea[idTouchPoint]][i])
					{
						intersectStatus[selectedDragArea[idTouchPoint]][i] = false
						send_string virtual, "STR_RESP_HEADER_DRAG_ITEM_EXIT_DROP_AREA,itoa(dragAreas[selectedDragArea[idTouchPoint]].id),DELIM_PARAM,itoa(dragAreas[i].id)"
					}
				}
			}
		}
	}
	
}

#define INCLUDE_MODERO_NOTIFY_TOUCH_COORDINATES_RELEASE
// Note: This will get triggered AFTER a release event handler in a button_event
// Note: If push/release coordinate reporting is enabled a release anywhere on the panel will trigger this function
define_function moderoNotifyTouchCoordinatesRelease (dev panel, integer nX, integer nY)
{
	// panel is the touch panel
	// nX is the X coordinate
	// nY is the Y Coordinate
	
	stack_var integer idTouchPoint
	stack_var Point p
	stack_var integer i
	stack_var integer isDroppedOntoDragArea
	
	isDroppedOntoDragArea = false
	
	setPointCoords (p, nX, nY)
	idTouchPoint =  getClosestTouchPoint(p)
	setTouchPointCoords (idTouchPoint, nX, nY)
	setTouchPointDeactive (idTouchPoint)
	
	
	if (selectedDragArea[idTouchPoint])
	{
		for (i=1; i<= length_array(dropAreas); i++)
		{
			if (isCoordWithinBounds(nX, nY, dropAreas[i]))
			{
				isDroppedOntoDragArea = true
				send_string virtual, "STR_RESP_HEADER_DRAG_ITEM_DROPPED_ON_DROP_AREA,itoa(dragAreas[selectedDragArea[idTouchPoint]].id),DELIM_PARAM,itoa(dropAreas[i].id)"
			}
		}
		
		if (!isDroppedOntoDragArea)
		{
			send_string virtual, "STR_RESP_HEADER_DRAG_ITEM_DESELECTED,itoa(dragAreas[selectedDragArea[idTouchPoint]].id)"
		}
		
		for (i=1; i<=MAX_DROP_AREAS; i++)
		{
			intersectStatus[selectedDragArea[idTouchPoint]][i] = false
		}
		
		selectedDragArea[idTouchPoint] = 0
	}
}

#include 'amx-modero-listener'	// copy modero listener notify callback functions above this line



define_start


define_event

data_event[panel]
{
	online:
	{
		moderoEnableTouchCoordinateTrackingPressReleaseMove (panel)
	}
}

data_event[virtual]
{
	command:
	{
		stack_var char header[50]
		
		header = remove_string(data.text,DELIM_HEADER,1)
		
		switch (header)
		{
			case CMD_HEADER_DEFINE_DRAG_ITEM:
			{
				// <id>,<left>,<top>,<width>,<height>
				integer id
				_bounds bounds
				
				id = atoi(remove_string (data.text,DELIM_PARAM,1))
				bounds.left = atoi(remove_string (data.text,DELIM_PARAM,1))
				bounds.top = atoi(remove_string (data.text,DELIM_PARAM,1))
				bounds.width = atoi(remove_string (data.text,DELIM_PARAM,1))
				bounds.height = atoi(data.text)
				
				addDragArea (id, bounds)
			}
			
			case CMD_HEADER_DEFINE_DROP_AREA:
			{
				// <id>,<left>,<top>,<width>,<height>
				integer id
				_bounds bounds
				
				id = atoi(remove_string (data.text,DELIM_PARAM,1))
				bounds.left = atoi(remove_string (data.text,DELIM_PARAM,1))
				bounds.top = atoi(remove_string (data.text,DELIM_PARAM,1))
				bounds.width = atoi(remove_string (data.text,DELIM_PARAM,1))
				bounds.height = atoi(data.text)
				
				addDropArea (id, bounds)
			}
		}
	}
}
