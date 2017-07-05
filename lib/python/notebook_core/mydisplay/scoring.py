import scipy as S

def sse_score(gt,predictions):
    predictions = S.array(predictions,ndmin=2)
    N,M = predictions.shape
    
    errors = [ S.power(S.maximum(0.0,row)-S.maximum(0.0,gt),2.0).mean(1) for row in predictions]#we expect a vector, but if we get a matrix, this mean is more deffensive. (will cause an error later)
    return S.absolute(S.array(errors).ravel())

def wPGP_single(gt,in_pred):
    if gt.ndim == 2:
        gt = gt[0]
    r_max = gt.max()
    
    in_pred = S.minimum(in_pred,1.0)
    
    reward = (gt*S.minimum(gt,in_pred)).sum()/S.power(gt,2.0).sum()
    
    
    penalty_num = (
        (r_max - gt)
        *(in_pred - gt)
        *S.array(in_pred > gt,dtype=S.float_)
    ).sum()
    penalty_denom = S.power(r_max - gt,2.0).sum()
    penalty = penalty_num / penalty_denom
    
    wpgp_score = 0.5 + 0.5*(reward-penalty)
    #assert wpgp_score <= 1.0 and wpgp_score >= 0.0, "PGP score not in acceptable range"
    if wpgp_score >1.0 or wpgp_score < 0.0:
	import sys
	sys.stderr.write("There was a problem withthe pgp score {} \n".format(wpgp_score))
	return 0.5
    return wpgp_score

def wPGP(gt,in_pred):
    gt = S.array(gt,ndmin=2)
    in_pred = S.array(in_pred,ndmin=2)
    #N,M = in_pred.shape
    return S.array([wPGP_single(gt[0],p) for p in in_pred])
