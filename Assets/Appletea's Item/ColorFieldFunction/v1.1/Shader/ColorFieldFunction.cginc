//Rotate Function
//–¼‘Od•¡–h~‚Ìˆ×‘•ü‚µ‚Ä‚¢‚Ü‚·
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
	//clamp‚Å-1`1‚Ì”ÍˆÍ‚ğØ‚èæ‚èA³‹K‰»‚·‚é
	return (clamp(p.x, -1, 1) + 1) / 2;
}
			
			
float ContinuousWrapper(float3 p, float shift, float delta, float Shape, float interval, float freq)
{
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


//ŠeField Fuction‚É‘Î‚µ‚Ä§Œä‚ğ—^‚¦‚é
float Fieldfunction(float3 p, float3 angle, float dispersion, float flatMode, float dotMode, float Shape, float interval, float Mode, float speed, float waveFreq, float mShift)
{
	//2D Option
	p = flatMode ? float3(p.xy, 0) : p;
				
	//Œø‰Ê‚Ì‰ñ“]
	angle = UNITY_PI * angle / 180;
	p.yz = rot_FORCOLORFIELDFUNCTION(p.yz, angle.x);
	p.zx = rot_FORCOLORFIELDFUNCTION(p.zx, angle.y);
	p.xy = rot_FORCOLORFIELDFUNCTION(p.xy, angle.z);
				
	//”gŒ`‚Ì•ªU’l:dispersion
				
	//”gŒ`‚Ìü”g”:waveFreq
					
	//”gŒ`ŠÔ‚Ì‹——£:interval
				
	//’è”(5”{)
	//‚±‚Ì’l‚ÍŠT‚Ë•‚Ìâ‘Î’l‚É“–‚½‚é
	//float tau = 5 * 2.35 * dispersion;
				
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