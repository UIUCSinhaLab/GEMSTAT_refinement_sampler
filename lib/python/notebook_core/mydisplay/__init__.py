import scipy as S
import pylab


def plot_predictions_variance(in_read_predictions, true_data=None,ax=None,show_cov=False):
    pred_mean = in_read_predictions.mean(0)
    pred_std = in_read_predictions.std(0)
    
    if ax == None:
        fig = pylab.figure()
        ax = fig.add_subplot(111)
    
    #pylab.plot(true_data/true_data.max(0), label="true")
    ax.plot(true_data, label="true")
    #pylab.plot(pred_mean, label="mean")
    #pylab.plot(pred_std, label="std")
    from errorfill import errorfill
    x = range(true_data.size)
    #errorfill(x, pred_mean/pred_mean.max(0), pred_std/pred_mean.max(0))
    errorfill(x, pred_mean, pred_std,ax=ax)
    ax.set_ylim(0.0,None)
    ax.legend()
    ax.set_title("Predictions vs True")
    
    if show_cov:
        coef_of_var = pred_std/pred_mean
        ax.plot(coef_of_var, label="coefficient of variation for predictions")
        ax.legend()

def plot_predictions_all(in_read_predictions, ground_truth_data=None,ax=None,alpha=None,gt_color="blue",pred_color="green",gt_label="true"):
	fig = None
	if ax == None:
		fig = pylab.figure()
		ax = fig.add_subplot(111)
	ax.plot(ground_truth_data,label=gt_label,color=gt_color)
	
	if alpha is None:
		alpha = S.minimum(20.0*S.power(in_read_predictions.shape[0],-1.0),1.0)
	
	for row in in_read_predictions:
		ax.plot(row,alpha=alpha,color=pred_color,label=None)
	
	ax.legend()
	return ax

def plot_one_fit(filename, title=None,ax=None,slicer0=None,slicer1=None):
    data = load_outfile(filename)
    if slicer0 is not None:
        data = data[slicer0,:]
    if slicer1 is not None:
        data = data[:,slicer1]
    
    
    if ax is None:
        fig = pylab.figure()
        ax = fig.add_subplot(111)
    
    #ax.set_ylim(-0.1,1.1)
    
    if title != None:
        ax.set_title(title)
    ax.plot(data[0], label="true")
    ax.plot(data[1], label="predicted")
    ax.legend()
    
    return data

def curve_densities(_data,bins=40):
        bins_mult = bins/_data.max()
        density_matrix = S.zeros((bins+1,_data.shape[1]))
        for row in _data:
                for j in range(len(row)):
                        density_matrix[S.floor(row[j]*bins_mult),j] += 1.0;
        density_matrix[density_matrix == 0.0] = float("-inf")

        density_figure = pylab.figure()
        pylab.matshow(density_matrix[::-1])
