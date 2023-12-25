
using System.Diagnostics;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

//SceneChangerはLightControllerに線形補間で切り替えれるようにするアタッチメントです。

public class SceneChanger : UdonSharpBehaviour
{
    //カウントダウン秒数
    private float ChangeTime = 0;
    //SceneChangeの種類
    private int FlagType = 2;
    //呼び出した本体のScript
    private LightController LightController_Origin;
    //変化先のLightController
    private LightController LightController_Next;
    //SetParameterするSharedMaterial
    private Material[] WriteMaterial;

    //管理変数
    private float LastTime = 0;
    private bool Callflag = false;

    //Materialの値一時保存用
    private Color[] _ActiveColor = new Color[3];
    private Color[] _PassiveColor = new Color[3];
    private Vector3[] _CenterPosition = new Vector3[3];
    private Vector3[] _Rotation = new Vector3[3];
    private float[] _Sigma = new float[3];
    private float[] _Wave_Frequency = new float[3];
    private float[] _Interval = new float[3];
    private float[] _Manual_Shift = new float[3];

    //LightControllerから呼び出されるときの処理
    public void CallSceneChange(float _ChangeTime, int _FlagType, LightController _LightController_Origin, LightController _LightController_Next, Material[] _WriteMaterial)
    {
        UnityEngine.Debug.Log("Called");
        //Private変数に移す
        //途中割込みは演出の表現を考えてある程度許可する
        if (!Callflag)
        {
            ChangeTime = _ChangeTime;
            FlagType = _FlagType;
            WriteMaterial = _WriteMaterial;
            LastTime = Time.time;
        }

        LightController_Origin = _LightController_Origin;
        LightController_Next = _LightController_Next;

        //Update内の処理を開始
        Callflag = true;
    }

    private void WriteParameter(float _ChangeParameter)
    {
        LightController_Origin.ParameterShare(out _ActiveColor[0], out _PassiveColor[0], out _CenterPosition[0], out _Rotation[0], out _Sigma[0], out _Wave_Frequency[0], out _Interval[0], out _Manual_Shift[0]);
        if(LightController_Next != null)
        LightController_Next.ParameterShare(out _ActiveColor[1], out _PassiveColor[1], out _CenterPosition[1], out _Rotation[1], out _Sigma[1], out _Wave_Frequency[1], out _Interval[1], out _Manual_Shift[1]);
        LinearInterpolation(_ChangeParameter);
        for (int i = 0; i < WriteMaterial.Length; i++)
        {
            WriteMaterial[i].SetColor("_Color", _ActiveColor[2]);
            WriteMaterial[i].SetColor("_PassiveColor", _PassiveColor[2]);
            WriteMaterial[i].SetVector("_CenterPosition", new Vector4(_CenterPosition[2].x, _CenterPosition[2].y, _CenterPosition[2].z, 0));
            WriteMaterial[i].SetVector("_Rotation", new Vector4(_Rotation[2].x, _Rotation[2].y, _Rotation[2].z, 0));
            WriteMaterial[i].SetFloat("_Width", _Sigma[2]);
            WriteMaterial[i].SetFloat("_waveFreq", _Wave_Frequency[2]);
            WriteMaterial[i].SetFloat("_Interval", _Interval[2]);
            WriteMaterial[i].SetFloat("_mShift", _Manual_Shift[2]);
        }
    }

    private void LinearInterpolation(float _ChangeParameter)
    {
        FadeInOut();
        _ActiveColor[2] = Color.Lerp(_ActiveColor[0], _ActiveColor[1], _ChangeParameter);
        _PassiveColor[2] = Color.Lerp(_PassiveColor[0], _PassiveColor[1], _ChangeParameter);
        _CenterPosition[2] = Vector3.Lerp(_CenterPosition[0], _CenterPosition[1], _ChangeParameter);
        _Rotation[2] = Vector3.Lerp(_Rotation[0], _Rotation[1], _ChangeParameter);
        _Sigma[2] = Mathf.Lerp(_Sigma[0], _Sigma[1], _ChangeParameter);
        _Wave_Frequency[2] = Mathf.Lerp(_Wave_Frequency[0], _Wave_Frequency[1], _ChangeParameter);
        _Interval[2] = Mathf.Lerp(_Interval[0], _Interval[1], _ChangeParameter);
        _Manual_Shift[2] = Mathf.Lerp(_Manual_Shift[0], _Manual_Shift[1], _ChangeParameter);
    }

    private void FadeInOut()
    {
        switch(FlagType)
        {
            case 0:
                //そもそもなにもかけない場合:なんでこれを呼び出せたか知らないが、Lerpしないように両方同じ色に
                CopyShaderParameter();
                break;
            case 1:
                //FadeIn
                CopyShaderParameter();
                _ActiveColor[0] = Color.black;
                _PassiveColor[0] = Color.black;
                break;
            case 2:
                //FadeOut
                CopyShaderParameter();
                _ActiveColor[1] = Color.black;
                _PassiveColor[1] = Color.black;
                break;
            case 3:
                //LinearInterpolation
                if (LightController_Next = null)
                {
                    CopyShaderParameter();
                    _ActiveColor[1] = Color.black;
                    _PassiveColor[1] = Color.black;
                }
                break;
        }
    }

    private void CopyShaderParameter()
    {
        _ActiveColor[1] = _ActiveColor[0];
        _PassiveColor[1] = _PassiveColor[0];
        _CenterPosition[1] = _CenterPosition[0];
        _Rotation[1] = _Rotation[0];
        _Sigma[1] = _Sigma[0];
        _Wave_Frequency[1] = _Wave_Frequency[0];
        _Interval[1] = _Interval[0];
        _Manual_Shift[1] = _Manual_Shift[0];
    }

    private void Update()
    {
        if (Callflag)
        {
            //線形補間に利用する0～1のパラメータ
            float ChangeParameter = Mathf.Clamp01((Time.time - LastTime) / ChangeTime);
            UnityEngine.Debug.Log(ChangeParameter);
            WriteParameter(ChangeParameter);
            if(ChangeParameter >= 1)
            {
                //パラメータのリセット
                ChangeTime = 0;
                FlagType = 2;
                LightController_Origin = null;
                LightController_Next = null;
                WriteMaterial = null;
                LastTime = 0;
                Callflag = false;
                this.gameObject.SetActive(false);
            }

        }
        /*else
        {
            LastTime = Time.time;
        }*/
    }
}
