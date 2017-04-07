class FigHolder(object):
    """Base class for all the figure holders we might implement."""
    def __init__(self, thefig):
        self.fig = thefig
    
    def add_subplot(self):
        pass
    
    def show(self):
        self.fig.tight_layout()
        self.fig.show()

class FlowGridHolder(FigHolder):
    def __init__(self, thefig, max_horizontal=None):
        self.x_max = max_horizontal
        super(FlowGridHolder,self).__init__(thefig)
    
    def add_subplot(self):
        n = len(self.fig.axes)
        if n == 0:
            return self.fig.add_subplot(1,1,1)
        y = max([i.get_geometry()[0] for i in self.fig.axes])
        x = max([i.get_geometry()[1] for i in self.fig.axes])
        if self.x_max is None or x < self.x_max:
            x+=1
        elif n+1 > x*y:
            y+=1
        for one_axis in self.fig.axes:
            _,_,c = one_axis.get_geometry()
            one_axis.change_geometry(y,x,c)
        new_ax = self.fig.add_subplot(y,x,n+1)
        return new_ax