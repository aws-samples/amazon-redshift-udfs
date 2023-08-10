create or replace function fn_levenshtein_distance(a varchar, b varchar) returns integer as
$$

def levenshtein_distance(a, len_a, b, len_b):
    d = [[0] * (len_b + 1) for i in range(len_a + 1)]  

    for i in range(1, len_a + 1):
        d[i][0] = i

    for j in range(1, len_b + 1):
        d[0][j] = j
    
    for j in range(1, len_b + 1):
        for i in range(1, len_a + 1):
            if a[i - 1] == b[j - 1]:
                cost = 0
            else:
                cost = 1
            d[i][j] = min(d[i - 1][j] + 1,      # deletion
                          d[i][j - 1] + 1,      # insertion
                          d[i - 1][j - 1] + cost) # substitution   

    return d[len_a][len_b]

def distance(a, b):
	if a is None:
		len_a = 0
	else:
		len_a = len(a)
	if b is None:
		len_b = 0
	else:
		len_b = len(b)
	if len_a == 0:
		return len_b
	elif len_b == 0:
		return len_a
	else:
		return levenshtein_distance(a, len_a, b, len_b)

return distance(a, b)
$$
language plpythonu immutable;
