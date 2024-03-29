//Rotate Function
//名前重複防止の為装飾しています
float2 rot_FORCOLORFIELDFUNCTION(float2 p, float a) { return float2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a)); }
			
float mod(float y, float x) { return y - floor(y / x) * x; }
			
float Gaussian(float r, float delta)
{
	return exp(-(pow(r, 2) / (2 * delta)));
}
			
float Wavelet(float r, float delta, float freq)
{
	float omega = 2 * UNITY_PI * freq;
	return saturate(cos(omega * r) * exp(-(pow(r, 2) / (2 * delta))));
}
			
float Gradient(float3 p)
{
	//clampで-1〜1の範囲を切り取り、正規化する
	return (clamp(p.x, -1, 1) + 1) / 2;
}
			
			
float ContinuousWrapper(float3 p, float shift, float delta, float Shape, float interval, float freq)
{	
	//FWHM(1.2倍)
	//半値全幅の1.2倍程度ずらすと重複が起きない状態からシフトが可能です。
	//float FWHM = 1.2 * 2.35 * sqrt(delta);
	//interval += FWHM;
	
	if(Shape == 0) return Gaussian(mod((length(p) - shift), 2 * interval) - interval, delta);
	else if(Shape == 1) return Wavelet(mod((length(p) - shift), 2 * interval) - interval, delta, freq);
	else return Gradient(mod(p / delta - shift.xxx, 2 * interval) - interval);
}
			
float OneshotWrapper(float3 p, float delta, float Shape, float freq, float mShift)
{
	if(Shape == 0) return Gaussian(length(p) - mShift, delta);
	else if(Shape == 1) return Wavelet(length(p) - mShift, delta, freq);
	else return Gradient(p / delta - mShift.xxx);
}


//各Field Fuctionに対して制御を与える
float Fieldfunction(float3 p, float3 angle, float dispersion, float flatMode, float dotMode, float Shape, float interval, float Mode, float speed, float waveFreq, float mShift)
{
	//2D Option
	p = flatMode ? float3(p.xy, 0) : p;
				
	//効果の回転
	angle = UNITY_PI * angle / 180;
	p.yz = rot_FORCOLORFIELDFUNCTION(p.yz, angle.x);
	p.zx = rot_FORCOLORFIELDFUNCTION(p.zx, angle.y);
	p.xy = rot_FORCOLORFIELDFUNCTION(p.xy, angle.z);
				
	//波形の分散値:dispersion
				
	//波形の周波数:waveFreq
					
	//波形間の距離:interval
				
	float parameter = 0;
	
	if(Mode) parameter = OneshotWrapper(p, dispersion, Shape, waveFreq, mShift);
	else parameter = ContinuousWrapper(p, speed * _Time.y, dispersion, Shape, interval, waveFreq);
				
	//2bit Option
	parameter = dotMode ? step(0.5, parameter) : parameter;
	return parameter;
}

float4 ColorFieldFunction(float4 activecolor, float4 passivecolor, float3 pos, float3 angle, float width, float flatMode, float dotMode, float Shape, float interval, float Mode, float speed, float wavefreq, float mshift)
{
	return lerp(activecolor, passivecolor, Fieldfunction(pos, angle, width, flatMode, dotMode, Shape, interval, Mode, speed, wavefreq, mshift));
}